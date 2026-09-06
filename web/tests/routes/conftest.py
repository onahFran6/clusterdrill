"""Shared fixtures for route-level (httpx.ASGITransport) tests.

Key gotcha these fixtures exist to handle: several router modules did
`from questions import bank` (a from-import) rather than `import questions`
- correct for production code (bank is only ever mutated in place via
bank.refresh(), never reassigned, so the binding stays valid for the app's
whole lifetime), but it means swapping in a fake bank for a test requires
patching each importing module's own local `bank` name individually
(monkeypatch.setattr(routers.pages, "bank", fake_bank)), not
questions.bank - patching the latter would leave every router still
pointing at the real singleton. See services/question_view.py's own
docstring for the identical gotcha with _current_question_workdir.
"""
from __future__ import annotations

import sys
from pathlib import Path

import httpx
import pytest

WEB_DIR = Path(__file__).resolve().parent.parent.parent
if str(WEB_DIR) not in sys.path:
    sys.path.insert(0, str(WEB_DIR))

import node_topology
import profile_store
import rbac
import routers.health as health
import routers.pages as pages
import routers.sessions_router as sessions_router
import services.question_view as question_view
import users
from app import app
from sessions import exam_result_store
from sessions import store as session_store
from ttyd_manager import manager as ttyd_manager

TEST_USERNAME = "tester"
TEST_PASSWORD = "test-password-not-real"
TEST_USER = users.User(
    user_id="tester", username=TEST_USERNAME, is_admin=True, created_at="2026-01-01T00:00:00Z",
)


@pytest.fixture(autouse=True)
def _isolate_workdir_root(monkeypatch, tmp_path):
    """question_context() (services/question_view.py) does a real
    `workdir.mkdir(parents=True, exist_ok=True)` under WORK_DIR_ROOT (real
    default: ~/practice-work) on every question view, and end_session()
    rmtree's the same path on cleanup - without this, route tests would
    create/delete real directories in the test-runner's actual home
    directory, named after fixture qids. Redirect to a tmp_path instead."""
    monkeypatch.setattr(question_view, "WORK_DIR_ROOT", tmp_path / "practice-work")


@pytest.fixture(autouse=True)
def _clean_session_store():
    """sessions.store is a real, process-wide singleton (same pattern as
    auth.py's globals) - reset around every route test so one test's
    started session can't leak into the next."""
    session_store.clear()
    yield
    session_store.clear()


@pytest.fixture(autouse=True)
def _clean_exam_result_store():
    """sessions.exam_result_store is the same kind of process-
    wide singleton as sessions.store above - reset for the same reason."""
    exam_result_store.clear_all()
    yield
    exam_result_store.clear_all()


@pytest.fixture
def wire_fake_bank(monkeypatch):
    """Returns a function that patches a given QuestionBank into every
    module that imported `bank` by name. questions_router.py no longer has
    its own `bank` reference (its handlers go through
    services.question_view.get_question_or_404 instead, patched via
    question_view below) - only patch modules that actually have the
    attribute, matching whichever modules currently import it."""

    def _wire(bank):
        for module in (pages, sessions_router, health, question_view):
            monkeypatch.setattr(module, "bank", bank)
        return bank

    return _wire


@pytest.fixture
def fake_bank(question_bank_factory, wire_fake_bank):
    """The common case: a small bank, wired into every router at once."""
    return wire_fake_bank(question_bank_factory({"topic-a": 3, "topic-b": 1}))


@pytest.fixture(autouse=True)
def fake_profile(monkeypatch):
    """Every page/question route calls profile_store.get_profile() at least
    once - the real implementation shells out to kubectl. profile_store is
    always accessed via whole-module attribute access (`import
    profile_store`, never a from-import) in every router, so patching it
    once here covers all of them. Autouse: no route test should ever
    accidentally reach a real kubectl call for lack of remembering this.

    boss_unlocked and has_achievement are further, separate kubectl-backed
    profile_store calls - both default to False here (no boss fights
    unlocked, no daily challenge cleared yet); tests that specifically need
    either True override it themselves (see tests/routes/test_sessions_
    routes.py's start-boss/start-daily tests).
    """
    empty = profile_store.Profile(spec=dict(profile_store._EMPTY_PROFILE_SPEC))
    monkeypatch.setattr(profile_store, "get_profile", lambda user_id=None: empty)
    monkeypatch.setattr(profile_store, "boss_unlocked", lambda topic, user_id=None: False)
    monkeypatch.setattr(profile_store, "has_achievement", lambda name, user_id=None: False)
    # node_topology.get_topology() (issue #122) is the same kind of
    # always-called, kubectl-backed call question_context() makes - same
    # autouse reasoning as the profile_store mocks above.
    monkeypatch.setattr(node_topology, "get_topology", lambda **kw: node_topology._EMPTY)


@pytest.fixture(autouse=True)
def fake_user_store(monkeypatch):
    """A real POST /login calls users.authenticate(), which shells out to
    kubectl for real - same reasoning as fake_profile above. One fixed
    admin test account (TEST_USERNAME/TEST_PASSWORD) is enough for every
    route test that needs to actually log in; tests/test_users.py covers
    users.py's own account CRUD/hashing logic against a fake cluster."""

    def fake_authenticate(username: str, password: str):
        if username == TEST_USERNAME and password == TEST_PASSWORD:
            return TEST_USER
        return None

    monkeypatch.setattr(users, "authenticate", fake_authenticate)
    monkeypatch.setattr(users, "get_user", lambda user_id: TEST_USER if user_id == "tester" else None)
    return TEST_USER


@pytest.fixture(autouse=True)
def fake_ttyd_teardown(monkeypatch):
    """admin_router.py's delete-user route shells out to real tmux via
    ttyd_manager.kill_user_tmux_sessions - same reasoning as fake_profile/
    fake_user_store above. tests/test_ttyd_manager.py covers that
    function's own argv shape against a mocked subprocess.run."""
    monkeypatch.setattr(ttyd_manager, "kill_user_tmux_sessions", lambda user_id: None)


@pytest.fixture(autouse=True)
def fake_rbac(monkeypatch):
    """admin_router.py's create/delete-user routes shell out to real
    kubectl via rbac.ensure_user_service_account/delete_user_service_account
    - same reasoning as fake_ttyd_teardown above. tests/test_rbac.py covers
    that module's own logic against a fake cluster."""
    monkeypatch.setattr(rbac, "ensure_user_service_account", lambda user_id: True)
    monkeypatch.setattr(rbac, "delete_user_service_account", lambda user_id: None)


@pytest.fixture
async def client():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
