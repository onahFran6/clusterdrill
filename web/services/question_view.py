"""Question-page view-building logic - extracted from app.py's original
monolith (2026-08 restructure) with no behavior change, just a new home.

Owns everything about turning a qid into question.html's template context:
Markdown/diagram rendering, the Discovery Path narrative, session-position
resolution, and the per-question terminal working directory. Distinct from
questions.py (which only ever discovers/reads question folders from disk,
per its own docstring: "never touches lib/*, never calls setup.sh/check.sh
itself") - the auto-provisioning and terminal-cwd bookkeeping here are
view-layer concerns, not question-bank data, so they live here instead.
"""
from __future__ import annotations

import html
import json
import logging
import re
from pathlib import Path
from typing import Optional

import auth
import markdown as md
import node_topology
import profile_store
from fastapi import HTTPException
from grading_client import namespaced_id, run_setup
from sessions import BOSS_MAX_HP
from sessions import store as session_store
from starlette.requests import Request
from ttyd_manager import manager as ttyd_manager

from questions import bank

logger = logging.getLogger("clusterdrill.question_view")

# Per-question terminal working directory, one flat folder per qid (not
# nested under a session/topic): a question id (e.g.
# q101-01-create-pod-imperative) is already globally unique and
# self-contained - it can turn up in a Fixed session today and a Mixed
# session next week, so nesting it under "whichever session drew it this
# time" would either duplicate the folder per run or silently reuse one
# across unrelated runs. Real exam questions work the same way: each one is
# independent, never scoped to "this batch". A future question that needs a
# local file to fix (troubleshooting-style, e.g. "this manifest has a bug")
# just has its setup.sh drop that file in here - nothing else has to change.
WORK_DIR_ROOT = Path.home() / "practice-work"


def question_workdir(qid: str) -> Path:
    return WORK_DIR_ROOT / qid


# In-memory, process-lifetime record of which (question, user) pairs have
# already had setup.sh auto-run this run (see question_context()) - same
# "resets on restart" pattern as sessions.py's ActiveSession. Re-running
# setup.sh is harmless (idempotent), this just avoids shelling out to
# kubectl on every single page view forever. Keyed by (qid, user_id) rather
# than qid alone - each user gets their own
# namespace now, so alice viewing q105-18 must not skip auto-provisioning
# for bob's own q105-18 namespace just because alice's copy already exists.
# user_id is None with the password gate off (no accounts) - every request
# in that mode shares this same key, exactly like before Phase 2.
_auto_provisioned_qids: set[tuple[str, Optional[str]]] = set()

# The most recently viewed question's working directory - passed to
# ttyd_manager.ensure_session() on every real terminal WebSocket connect
# (see routers/terminal_router.py), which only actually uses it if that
# tab's tmux session doesn't exist yet - never touches one you're already
# mid-command in. None until the first question is viewed, in which case a
# new session just starts wherever tmux's own default lands.
#
# Read from another module as `question_view._current_question_workdir`
# (module-attribute access), never `from services.question_view import
# _current_question_workdir` - a bare `from x import y` binds a name to
# whatever value `y` held at import time, which would freeze at None forever
# and never see this module's later `global` mutations below.
_current_question_workdir: str | None = None


def appliance_question_text(text: str) -> str:
    """Make question-bank paths usable inside the packaged appliance.

    Question content is authored in the repository, where Helm fixtures live
    below ``questions/``.  The appliance stores that directory at
    ``/opt/clusterdrill/questions/`` instead, and the learner's terminal starts
    in a separate practice-work directory.  Normalize the rendered text in one
    place so every command and prose reference stays usable after packaging.
    """
    text = re.sub(
        r"(?<!/)\bquestions/helm-crds/",
        "/opt/clusterdrill/questions/helm-crds/",
        text,
    )
    text = re.sub(
        r"\s*\(relative\s+to\s+(?:the\s+)?`practice-bank/`\s*(?:directory)?\)",
        "",
        text,
    )
    return text.replace("practice-bank/", "/opt/clusterdrill/")


def substitute_namespace(text: str, qid: str, user_id: Optional[str]) -> str:
    """Rewrites every literal occurrence of the bare question id in QUESTION.md/
    ANSWER.md text to the namespace that id's setup.sh/check.sh actually operate
    against for this viewer (grading_client.namespaced_id - the same suffix
    derivation full_reset/batch_cleanup already use, so the displayed text and
    the live cluster state can never disagree).

    Both files are authored against the bare id - per-user namespace
    suffixing only ever rewrote setup.sh/check.sh's own QUESTION_ID= line,
    not the prose/commands shown to the user. With no accounts
    (user_id=None) namespaced_id returns the id unchanged, so this is a
    no-op there.
    """
    namespace = namespaced_id(qid, user_id)
    if namespace == qid:
        return text
    # A question id is itself hyphenated, so \b's word/non-word boundary
    # would treat the "-" in some unrelated, longer hyphenated string (e.g.
    # a sibling id that happens to start with this one) as a valid boundary
    # and match inside it. Require the char on each side to be neither
    # alphanumeric nor "-" instead, so only a whole, standalone occurrence
    # of this exact id is rewritten.
    return re.sub(rf"(?<![a-z0-9-]){re.escape(qid)}(?![a-z0-9-])", namespace, text)


def render_markdown(text: str, qid: Optional[str] = None, user_id: Optional[str] = None) -> str:
    text = appliance_question_text(text)
    if qid:
        text = substitute_namespace(text, qid, user_id)
    return md.markdown(text, extensions=["fenced_code", "tables"])


def get_question_or_404(qid: str):
    """bank.refresh() + bank.get(qid) + 404-if-missing, in one place -
    previously copy-pasted verbatim in question_context() here and in both
    routers/questions_router.py handlers (check_question/reset_question).
    A change to the 404 shape now only needs to happen once."""
    bank.refresh()
    question = bank.get(qid)
    if question is None:
        raise HTTPException(status_code=404, detail=f"question '{qid}' not found")
    return question


# A still-unrendered placeholder left behind for any question/topic
# that hasn't had its diagram generated yet (see
# questions/_template/diagram.mmd). In practice this is rare - most
# per-question diagrams are generated and most
# topic primers are hand-authored - but read_diagram_mmd() below must not crash or render a
# "%% Placeholder" comment as if it were a real diagram either way.
_PLACEHOLDER_MARKER = "%% Placeholder"


def read_diagram_mmd(path: Path, missing_message: str) -> tuple[Optional[str], Optional[str]]:
    """Reads a .mmd file's raw text for client-side Mermaid rendering.

    Returns (mermaid_source, fallback_message). Exactly one of the two is
    non-None: mermaid_source when the file exists and has real content,
    fallback_message when it's missing or still the generator's placeholder
    text - mirrors question_context()'s existing missing-ANSWER.md handling
    (a friendly <em> message in place of raw content) rather than crashing
    or silently rendering a mermaid.js parse error to the tab.
    """
    if not path.exists():
        return None, missing_message
    text = path.read_text().strip()
    if not text or text.startswith(_PLACEHOLDER_MARKER):
        return None, "Diagram not yet generated for this item."
    return text, None


def read_diagram_json(path: Path) -> Optional[dict]:
    """Reads the Diagram tab rebuild's structured JSON (architecture +,
    for per-question diagrams, sequence - topic primers only ever have
    "architecture", see build_topic_primers/the rebuild plan). Returns None
    on anything short of a clean parse (missing file, malformed JSON, or a
    dict missing "architecture") so question_context() can fall back to the
    existing Mermaid path exactly like a missing diagram.mmd already does -
    this is read-only presentation data, never worth a 500 over.
    """
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text())
    except (json.JSONDecodeError, OSError):
        return None
    if not isinstance(data, dict) or "architecture" not in data:
        return None
    return data


def build_discovery_path_html(question, hint_html: str) -> Optional[str]:
    """Solution tab's "Discovery Path" view: a "how to think through it"
    narrative shown alongside the existing verbatim "Exact Solution", ported
    from an earlier prototype design - but generated from this question's own resource-kind
    sequence + Hint text rather than hand-authored, the same call already
    made for Sequence diagrams: 296 questions is too many to hand-write a
    discovery narrative for one at a time, and this data is already sitting
    right there from generate_diagram.py's sequence_json().

    Deliberately not as bespoke as prose a human would write per question
    (no unit-conversion traps or dry-run tips called out) - it's a real,
    always-available walkthrough of *this exact question's* relationships
    in creation order, not a placeholder. Returns None when there's no
    sequence data at all (diagram.json missing/malformed) so the Solution
    tab falls back to showing only Exact Solution, same graceful-degrade
    posture as every other optional field in this file.
    """
    diagram_data = read_diagram_json(question.diagram_json)
    seq = diagram_data.get("sequence") if diagram_data else None
    if not seq or not seq.get("steps"):
        return None

    esc = html.escape
    parts = [f"<p><strong>Step 1 - Understand what's involved.</strong> {esc(seq['description'])}</p>"]

    # The synthetic "kubectl -> X: creates" steps exist to give the Sequence
    # diagram's lifelines something to originate from - here they're noise,
    # not a distinct reasoning step, so only the real from-resource-to-
    # resource relationships become numbered steps.
    relationship_steps = [s for s in seq["steps"] if s["from"] != "kubectl"]
    step_num = 2
    if relationship_steps:
        parts.append(f"<p><strong>Step {step_num} - Work through the relationships in order.</strong></p><ul>")
        for s in relationship_steps:
            parts.append(f"<li><code>{esc(s['from'])} -&gt; {esc(s['to'])}</code>: {esc(s['label'])}</li>")
        parts.append("</ul>")
        step_num += 1

    if hint_html:
        parts.append(f"<p><strong>Step {step_num} - Search the docs.</strong></p>{hint_html}")
        step_num += 1

    parts.append(
        f"<p><strong>Step {step_num} - Verify.</strong> Once applied, "
        "<code>kubectl get</code>/<code>kubectl describe</code> the resources above to "
        "confirm the relationship actually took effect before running Check.</p>"
    )
    return "\n".join(parts)


def split_hint(question_md_text: str, qid: str, user_id: Optional[str]) -> tuple[str, str]:
    """Splits QUESTION.md into (task_html, hint_html).

    The folder-shape contract (questions/README.md) says QUESTION.md ends
    with a "## Hint" section containing a search-term string. Everything
    before that heading is the task; the heading's body is the hint.
    Displayed as-is, no link parsing / doc-search integration - just render the markdown.
    """
    match = re.search(r"^##\s+Hint\s*$", question_md_text, flags=re.MULTILINE)
    if not match:
        return render_markdown(question_md_text, qid, user_id), ""
    task_part = question_md_text[: match.start()]
    hint_part = question_md_text[match.end():]
    return render_markdown(task_part, qid, user_id), render_markdown(hint_part, qid, user_id)


def question_context(qid: str, tab: str = "task", user_id: Optional[str] = None) -> dict:
    """Builds the question.html template context.

    Session resolution: navigation (Previous/Skip), the position
    counter, and the progress bar all walk the *active session's* ordered
    qid list when one exists and contains this qid - not the full flat
    bank, per the ticket's requirement that "Question N of Total" reflect
    the session, e.g. "3 of 15" rather than "47 of 173".

    Documented fallback for a qid outside any active session (including
    "no session started yet"): rather than redirect away or error, the
    question is shown as its own single-question session-of-one - "Question
    1 of 1", no Previous/Skip targets. This was a judgment call (not
    specified) - a redirect-to-landing felt worse for two real cases this
    app needs to support: (a) a stale/bookmarked link to a qid from a
    session that has since ended, and (b) directly typing a qid to look
    something up without wanting to start a full session. Both are better
    served by "show me that question, plainly" than a bounce to /topics.
    It never crashes and never shows a bank-wide number that would be
    misleading relative to whatever session (if any) is active.
    """
    question = get_question_or_404(qid)

    # Auto-provision on first view (see _auto_provisioned_qids docstring
    # above): a real exam question's namespace/seed resources already exist
    # when you get the question, so this practice bank shouldn't require an
    # extra manual "Reset" click just to reach that starting state. Best
    # effort - if setup.sh fails (e.g. cluster unreachable), swallow it and
    # render the page anyway rather than 500 the whole question; the
    # existing Reset button remains available to retry by hand.
    provision_key = (qid, user_id)
    provision_error: Optional[str] = None
    if question.setup_sh.exists() and provision_key not in _auto_provisioned_qids:
        setup_result = run_setup(question.setup_sh, user_id=user_id)
        if setup_result.ok:
            _auto_provisioned_qids.add(provision_key)
        else:
            # Left out of _auto_provisioned_qids on failure (unlike the
            # success path above) so the next view of this question retries
            # setup.sh instead of permanently treating a transient failure
            # (cluster hiccup, RBAC race, SETUP_TIMEOUT_SECONDS) as done.
            provision_error = setup_result.error
            logger.warning(
                "auto-provision failed for %s (user=%s): %s", qid, user_id, setup_result.error,
            )

    # Per-question working directory (see WORK_DIR_ROOT above) - cheap local
    # mkdir, safe to redo on every view, unlike the kubectl-backed
    # auto-provision above. Recorded as "current" so a *new* terminal tab
    # opened while looking at this question starts here.
    global _current_question_workdir
    workdir = question_workdir(qid)
    workdir.mkdir(parents=True, exist_ok=True)
    _current_question_workdir = str(workdir)

    session = session_store.get(user_id)
    session_index = session.index_of(qid) if session else None
    # Bound once and reused below (the position==1/show_topic_primer split,
    # the combo lookup, and the returned "in_active_session" field all need
    # this same guard - previously each repeated the full compound
    # condition independently, five call sites that had to be kept in sync
    # by hand).
    in_session = session is not None and session_index is not None

    if in_session:
        session.visited_qids.add(qid)
        total = len(session)
        position = session_index + 1
        prev_id = session.question_ids[session_index - 1] if session_index > 0 else None
        next_id = (
            session.question_ids[session_index + 1]
            if session_index + 1 < total
            else None
        )
        session_mode = session.mode
        session_topic = session.topic
        # Exam mode is the first mode where topic=None can mean
        # "a candidate-chosen subset of topics", not just "every topic,
        # unconditionally" like Mixed/Daily always were - the status bar's
        # plain "all topics" fallback (question.html) would otherwise
        # silently lie about a genuinely narrowed exam. Derived from the
        # session's own question_ids rather than stored on ActiveSession
        # itself, so this is purely a display computation.
        if session_mode == "exam" and session_topic is None:
            exam_topics = {bank.get(qid).topic for qid in session.question_ids}
            if len(exam_topics) < len(bank.topics()):
                session_topic = f"{len(exam_topics)} topics"
        timer_enabled = session.timer_enabled
        timer_deadline = session.deadline
        # Question navigator - every question in
        # the session, in order, with enough per-entry state for the
        # palette to mark current/visited/passed/failed without the
        # template needing to know session.question_ids at all. A qid can
        # be both visited and passed/failed at once; passed/failed simply
        # takes priority in the status shown, since it's strictly more
        # specific information than "merely looked at it."
        palette = [
            {
                "id": session_qid,
                "position": i + 1,
                "current": session_qid == qid,
                "status": (
                    "passed" if session_qid in session.passed_qids
                    else "failed" if session_qid in session.failed_qids
                    else "visited" if session_qid in session.visited_qids
                    else "unvisited"
                ),
            }
            for i, session_qid in enumerate(session.question_ids)
        ]
    else:
        # Fallback: qid isn't part of any active session (or none is
        # active at all) - treat it as a standalone session-of-one. See
        # this function's docstring for why a redirect wasn't chosen.
        total = 1
        position = 1
        prev_id = None
        next_id = None
        session_mode = None
        session_topic = None
        timer_enabled = False
        timer_deadline = None
        palette = []

    # Deferred grading: a real exam gives no
    # interim feedback and, per this ticket's own explicit call, no peek
    # at the reference solution mid-attempt either - a candidate shouldn't
    # be able to see how a task is meant to be solved before submitting.
    # tab is forced away from "solution" (a stale bookmark/link, or a
    # forged ?tab=solution query param) rather than merely hiding the tab
    # in the nav - and answer_html/discovery_path_html below are never
    # even computed from the real ANSWER.md in that case, so the real
    # solution text never reaches the rendered page at all (not just
    # hidden client-side, where view-source would still reveal it).
    is_exam_session = session_mode == "exam"
    if is_exam_session and tab == "solution":
        tab = "task"

    task_html, hint_html = "", ""
    if question.question_md.exists():
        task_html, hint_html = split_hint(question.question_md.read_text(), qid, user_id)
    else:
        task_html = "<p><em>QUESTION.md missing for this question.</em></p>"

    if is_exam_session:
        answer_html = "<p><em>Solutions are hidden during a live exam - available after you submit.</em></p>"
        discovery_path_html = None
    else:
        answer_html = "<p><em>ANSWER.md missing for this question.</em></p>"
        if question.answer_md.exists():
            answer_html = render_markdown(question.answer_md.read_text(), qid, user_id)

        # Solution tab's Discovery Path/Exact Solution toggle (see
        # build_discovery_path_html() above) - deliberately computed from
        # this question's own diagram.json regardless of what the Diagram
        # tab itself is showing right now (which may be a topic primer
        # with no sequence at all on session position 1, per
        # show_topic_primer below) - the Solution tab is always about
        # *this* question, so it always uses *this* question's own
        # sequence data, never the topic primer's.
        discovery_path_html = build_discovery_path_html(question, hint_html)

    # Diagram tab content. "On session start" is interpreted as "the first
    # question of the active session"
    # (position == 1) - there is no separate session-start page besides
    # /topics and the first question view, so position 1 is the natural
    # stand-in for "session start" in this architecture. Every other
    # position in the session falls back to
    # that question's own per-question generated diagram.
    #
    # Mixed-mode edge case, a documented judgment call: a Mixed session has
    # no single topic (session.topic is None), so there is no one primer to
    # show. Rather than pick one topic's primer arbitrarily or show nothing
    # topic-specific, position 1 of a Mixed session shows that question's
    # own per-question diagram plus a short note explaining why (Mixed
    # spans every topic, so no single primer applies) - this keeps the tab
    # always showing *something* diagram-shaped rather than an empty state
    # on the very first question a candidate sees.
    at_session_start = position == 1 and in_session
    show_topic_primer = at_session_start and session.topic is not None
    mixed_session_start = at_session_start and session.topic is None

    # Personal-best time + attempt count for this exact
    # question (shown next to the checklist, "PB: 47s"), and the session's
    # current combo count (session-local, ActiveSession.combo - see its
    # field docstring in sessions.py). Both purely informational, same
    # invariant as everything else here: never fed back into grading.
    profile_snapshot = profile_store.get_profile(user_id).spec.get("questions", {}).get(qid, {})
    combo = session.combo if in_session else 0

    if show_topic_primer:
        diagram_mmd, diagram_fallback = read_diagram_mmd(
            bank.topic_diagram_mmd(question.topic),
            missing_message=f"No topic primer diagram found for '{question.topic}'.",
        )
        diagram_label = f"Topic primer: {question.topic}"
        diagram_data = read_diagram_json(bank.topic_diagram_json(question.topic))
    else:
        diagram_mmd, diagram_fallback = read_diagram_mmd(
            question.diagram_mmd,
            missing_message="No diagram generated for this question yet.",
        )
        diagram_label = f"Diagram: {question.id}"
        diagram_data = read_diagram_json(question.diagram_json)

    # Diagram tab rebuild: diagram_arch/diagram_seq are the new SVG
    # renderer's input (see static/diagram.js) - question.html renders the
    # Architecture/Sequence sub-tabs only when diagram_arch is present, and
    # falls back to the untouched diagram_mmd/Mermaid path above otherwise
    # (a question whose diagram.json is missing or failed to parse, which
    # shouldn't happen post-regen but is a real degrade-gracefully case
    # during rollout - same posture as every other "missing content" branch
    # in this function). Topic primers never have a "sequence" key (see
    # build_topic_primers.py / the rebuild plan) - diagram_seq is None in
    # that case and the template shows a short explanatory note instead of
    # an empty Sequence panel.
    diagram_arch = diagram_data.get("architecture") if diagram_data else None
    diagram_seq = diagram_data.get("sequence") if diagram_data else None

    return {
        "question": question,
        # Set only when this view's own auto-provision run just failed (see
        # provision_key/provision_error above) - the Reset button (can_reset
        # below) is the retry path, same as any other failed setup.sh run.
        "provision_error": provision_error,
        "task_html": task_html,
        "hint_html": hint_html,
        "answer_html": answer_html,
        "discovery_path_html": discovery_path_html,
        # Diagram tab. diagram_mmd is the raw Mermaid source (None
        # if missing/placeholder, in which case diagram_fallback is a
        # human-readable message instead) - see read_diagram_mmd() above
        # and this function's docstring-adjacent comment for the
        # session-start-vs-per-question resolution and the Mixed-mode call.
        "diagram_mmd": diagram_mmd,
        "diagram_fallback": diagram_fallback,
        "diagram_label": diagram_label,
        "diagram_is_topic_primer": show_topic_primer,
        "diagram_mixed_session_start": mixed_session_start,
        # Diagram tab rebuild (see read_diagram_json() above): parsed dicts
        # or None, serialized into <script type="application/json"> blocks
        # by question.html for static/diagram.js to render client-side.
        "diagram_arch": diagram_arch,
        "diagram_seq": diagram_seq,
        "tab": tab,
        "position": position,
        "total": total,
        "progress_pct": round((position / total) * 100) if total else 0,
        "prev_id": prev_id,
        "next_id": next_id,
        "palette": palette,
        "can_reset": question.setup_sh.exists(),
        "workdir": _current_question_workdir,
        "session_mode": session_mode,
        "session_topic": session_topic,
        "in_active_session": in_session,
        "is_exam_session": is_exam_session,
        # Server-authoritative countdown. deadline is a unix
        # timestamp computed once at session-start (sessions.py) - the
        # template/JS only ever read it, never compute or extend it, so a
        # refresh or Previous/Skip navigation shows the same countdown
        # rather than resetting it. Grading (Check/Reset below) never reads
        # these fields - purely informational.
        "timer_enabled": timer_enabled,
        "timer_deadline": timer_deadline,
        # Whether the app actually managed to spawn ttyd this run
        # (e.g. false if the binary wasn't on PATH - see ttyd_manager.py).
        # The iframe points at this app's own /terminal/ proxy
        # route, not ttyd_manager.base_url (127.0.0.1:7681) directly - see
        # routers/terminal_router.py. This is what makes "the password gate
        # covers the terminal too" true: the browser never talks to ttyd's
        # port directly, so there is nothing for a public tunnel or reverse
        # proxy in front of this app
        # to expose except this app's single port, and nothing reachable
        # pre-login except /login itself. It also fixes a real gap in
        # an SSH-tunnel deployment, which only forwards this app's port - the
        # terminal iframe was unreachable over that tunnel before this
        # change, since 7681 was never forwarded.
        "terminal_available": ttyd_manager.is_running,
        "terminal_url": "/terminal/t/1/",
        "terminal_max_tabs": ttyd_manager.max_tabs,
        # issue #122 (M7): which worker nodes (if any) a new terminal tab
        # can target, from a live topology query - never hardcoded, so
        # this stays correct if the cluster's node count ever changes
        # (see node_topology.py). Deliberately empty in no-accounts mode
        # even on a real multi-node cluster: a worker tab's isolation is
        # RBAC-scoped per logged-in user_id (rbac.py) - there is no
        # per-user identity to scope it to without accounts, and that
        # mode's terminal already runs under this app's own full admin
        # kubeconfig regardless (see ttyd_manager._spawn_env), so nothing
        # would actually be gained by offering it there.
        "worker_nodes": node_topology.get_topology().worker_nodes if user_id else (),
        "profile_snapshot": profile_snapshot,
        "combo": combo,
        # Boss mini-exam HP bar. is_boss_session gates the whole UI
        # element; boss_hp/boss_max_hp are the initial server-rendered
        # values, live-updated in place after each Check the same way
        # combo/PB-time already are (see app.js's updateProgressBadges()).
        "is_boss_session": in_session and session.mode == "boss",
        "boss_hp": session.hp if in_session and session.mode == "boss" else None,
        "boss_max_hp": BOSS_MAX_HP,
    }


def topic_progress_pct(profile_spec: dict, topic_question_ids: list[str]) -> int:
    """Percent of a topic's pool ever first-cleared, per the stored profile's
    per-question `passed` map. Cross-referenced against the bank's own
    topic grouping (not stored redundantly in the profile itself) - the
    profile only needs to know per-question pass state, this module already
    knows which questions belong to which topic.
    """
    if not topic_question_ids:
        return 0
    questions = profile_spec.get("questions", {})
    passed = sum(1 for qid in topic_question_ids if questions.get(qid, {}).get("passed"))
    return round(100 * passed / len(topic_question_ids))


def base_context(request: Request) -> dict:
    """Context fields every template-rendering route should merge in,
    regardless of page - the CSRF token (see auth.py's CSRF_SESSION_KEY),
    and the logged-in username plus an is-admin *hint* for
    _shell.html's nav, both read straight from the session cookie's cached
    copies rather than a fresh users.py lookup - see auth.py's
    USERNAME_KEY/IS_ADMIN_KEY docstring for why a cached hint is fine for
    display but never for the /admin routes' own authorization check."""
    return {
        "csrf_token": auth.get_csrf_token(request),
        "username": auth.current_username(request.session),
        "is_admin_hint": bool(request.session.get(auth.IS_ADMIN_KEY)),
    }
