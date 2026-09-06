"""Admin-only user management (add/reset-password/delete
user accounts). Gated on auth.require_admin for
every route in this router - see that dependency's docstring for why it's
a no-op when the password gate itself is disabled (local dev/SSH-tunnel).

No self-service sign-up anywhere in this app; this page is the only way
new accounts get created.
"""
from __future__ import annotations

import auth
import profile_store
import rbac
import users
from fastapi import APIRouter, BackgroundTasks, Depends, Form, HTTPException
from fastapi.responses import RedirectResponse
from grading_client import run_batch_cleanup
from services import question_view
from services.question_view import base_context
from sessions import store as session_store
from starlette.requests import Request
from templating import templates
from ttyd_manager import manager as ttyd_manager

from questions import LIB_DIR, bank

router = APIRouter(dependencies=[Depends(auth.require_admin)])

# Fixed codes rather than free-text in the redirect's query string - avoids
# ever putting a message that includes untrusted data (e.g. a username) in
# a URL, and keeps the actual wording in one place instead of duplicated at
# every RedirectResponse call site.
_SUCCESS_MESSAGES = {
    "added": "User added.",
    "reset": "Password reset.",
    "deleted": "User deleted.",
}


def _render(request: Request, *, error: str | None = None, success: str | None = None, status_code: int = 200):
    return templates.TemplateResponse(
        request, "admin.html",
        {
            **base_context(request),
            "active_nav": "admin",
            "users": sorted(users.list_users(), key=lambda u: u.username.lower()),
            "error": error,
            "success": _SUCCESS_MESSAGES.get(success),
            "current_user_id": auth.current_user_id(request.session),
        },
        status_code=status_code,
    )


@router.get("/admin")
def admin_page(request: Request):
    if users.single_user_mode():
        raise HTTPException(status_code=404, detail="User management is unavailable in single-user mode.")
    return _render(request, success=request.query_params.get("success"))


@router.post("/admin/users", dependencies=[Depends(auth.csrf_protect_form)])
def create_user_submit(
    request: Request,
    username: str = Form(...),
    password: str = Form(...),
    is_admin: bool = Form(False),
    csrf_token: str = Form(...),
):
    if users.single_user_mode():
        return _render(
            request,
            error="This local appliance is single-user. Use an isolated cluster per learner for shared access.",
            status_code=403,
        )
    try:
        new_user = users.create_user(username, password, is_admin=is_admin)
    except users.UsernameTakenError as exc:
        return _render(request, error=str(exc), status_code=409)
    except ValueError as exc:
        return _render(request, error=str(exc), status_code=400)
    # Provisions the ServiceAccount/kubeconfig this account's terminal will
    # authenticate as - best-effort: a failure here
    # doesn't block account creation, it just means that account's first
    # terminal falls back to the app's own kubeconfig until ttyd_manager's
    # own defensive retry (_spawn_env) succeeds later.
    rbac.ensure_user_service_account(new_user.user_id)
    return RedirectResponse(url="/admin?success=added", status_code=303)


@router.post("/admin/users/{user_id}/reset-password", dependencies=[Depends(auth.csrf_protect_form)])
def reset_password_submit(
    request: Request,
    user_id: str,
    password: str = Form(...),
    csrf_token: str = Form(...),
):
    try:
        ok = users.set_password(user_id, password)
    except ValueError as exc:
        return _render(request, error=str(exc), status_code=400)
    if not ok:
        return _render(request, error="User not found.", status_code=404)
    # Force that one account to re-login with the new password right away -
    # otherwise a still-open session on a device you no longer control
    # (the actual reason to reset someone's password) would keep working
    # until it naturally expires. See auth.revoke_user_sessions - scoped to
    # this account only, the other logged-in users are unaffected.
    auth.revoke_user_sessions(user_id)
    return RedirectResponse(url="/admin?success=reset", status_code=303)


@router.post("/admin/users/{user_id}/delete", dependencies=[Depends(auth.csrf_protect_form)])
def delete_user_submit(
    request: Request, background_tasks: BackgroundTasks, user_id: str, csrf_token: str = Form(...),
):
    # Two guardrails against locking every admin out of their own admin
    # page: never delete the account you're currently logged in as, and
    # never delete the last remaining admin account (even a different
    # admin deleting it would leave nobody able to reach /admin again).
    acting_user_id = auth.current_user_id(request.session)
    if acting_user_id is not None and acting_user_id == user_id:
        return _render(
            request,
            error="You can't delete your own account while logged in as it.",
            status_code=400,
        )
    target = users.get_user(user_id)
    if target is None:
        return _render(request, error="User not found.", status_code=404)
    remaining_admins = [u for u in users.list_users() if u.is_admin and u.user_id != user_id]
    if target.is_admin and not remaining_admins:
        return _render(
            request, error="Can't delete the last remaining admin account.", status_code=400,
        )
    users.delete_user(user_id)
    auth.revoke_user_sessions(user_id)
    # Tear down any live shell this account had open - a deleted account
    # must not leave a still-reachable terminal with no owner behind it
    #.
    ttyd_manager.kill_user_tmux_sessions(user_id)
    # And the ServiceAccount/kubeconfig backing that terminal's identity
    # - without this a still-open terminal process
    # (if kill_user_tmux_sessions raced with an active session) could keep
    # authenticating as a "deleted" user until its kubeconfig file and the
    # ServiceAccount it points at are actually gone.
    rbac.delete_user_service_account(user_id)
    # PLAN.md §4.12's cascade-teardown requirement: the guardrails above
    # only removed this account's *identity* (auth session, tmux, RBAC),
    # not the practice-session footprint that identity accumulated - a
    # deleted user must not leave that behind with no owner either.
    session_store.clear(user_id)
    stale_provision_keys = {key for key in question_view._auto_provisioned_qids if key[1] == user_id}
    question_view._auto_provisioned_qids.difference_update(stale_provision_keys)
    profile_store.delete_profile(user_id)
    # Namespace/cluster-scoped cleanup as a background task, the same
    # pattern sessions_router.py's session-end cleanup already uses -
    # potentially hundreds of `kubectl delete namespace` targets (every
    # question in the bank, not just ones provably touched by this user -
    # passing extras is harmless, batch_cleanup's --ignore-not-found
    # silently no-ops on anything never actually provisioned for them) is
    # not something an admin clicking "Delete" should have to wait on.
    bank.refresh()
    background_tasks.add_task(run_batch_cleanup, [q.id for q in bank.questions], LIB_DIR, user_id)
    return RedirectResponse(url="/admin?success=deleted", status_code=303)
