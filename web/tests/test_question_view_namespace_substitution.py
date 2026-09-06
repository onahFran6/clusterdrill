"""services/question_view.py's per-viewer namespace substitution (issue #95).

Per-user namespace suffixing was rolled out by mechanically rewriting
setup.sh/check.sh's own QUESTION_ID= line to append CLUSTERDRILL_NAMESPACE_SUFFIX,
but never touched QUESTION.md/ANSWER.md's prose and commands - so a suffixed
viewer was shown (and could copy-paste) a namespace name that setup.sh never
actually created for them. substitute_namespace()/render_markdown() close
that gap at render time, using grading_client.namespaced_id() as the single
source of truth both sides already agree on.
"""
from __future__ import annotations

import node_topology
import profile_store
import pytest
import services.question_view as question_view
from services.question_view import render_markdown, split_hint, substitute_namespace
from sessions import store as session_store


@pytest.fixture(autouse=True)
def _isolate_module_globals(monkeypatch):
    """Same reasoning as test_question_view_auto_provision.py's fixture of
    the same name: question_context() touches profile_store/session_store/
    node_topology process-wide singletons that must not leak into or be
    polluted by other test files - and get_profile/get_topology's real
    implementations shell out to kubectl, which has no place running in
    this test."""
    question_view._auto_provisioned_qids.clear()
    empty_profile = profile_store.Profile(spec=dict(profile_store._EMPTY_PROFILE_SPEC))
    monkeypatch.setattr(profile_store, "get_profile", lambda user_id=None: empty_profile)
    monkeypatch.setattr(node_topology, "get_topology", lambda **kw: node_topology._EMPTY)
    session_store.clear()
    yield
    question_view._auto_provisioned_qids.clear()
    session_store.clear()


def test_substitute_namespace_is_a_noop_with_no_accounts():
    text = "kubectl get pods -n q101-01-example"
    assert substitute_namespace(text, "q101-01-example", None) == text


def test_substitute_namespace_rewrites_every_occurrence_for_a_real_user():
    text = "**Namespace:** `q101-01-example`. Run kubectl get pods -n q101-01-example."
    rewritten = substitute_namespace(text, "q101-01-example", "alice")
    assert rewritten == (
        "**Namespace:** `q101-01-example-alice`. Run kubectl get pods -n q101-01-example-alice."
    )


def test_substitute_namespace_does_not_touch_a_different_id_sharing_a_prefix():
    # q101-01-example must not match inside the unrelated q101-01-example-2's text.
    text = "See q101-01-example-2 for a related case."
    assert substitute_namespace(text, "q101-01-example", "alice") == text


def test_render_markdown_substitutes_before_rendering():
    html = render_markdown("Namespace: `q101-01-example`", qid="q101-01-example", user_id="alice")
    assert "q101-01-example-alice" in html
    assert "q101-01-example<" not in html  # bare id no longer stands alone


def test_render_markdown_is_unchanged_when_qid_is_omitted():
    # Callers outside a question's own render (e.g. topic primers) that
    # never pass qid keep today's behavior exactly.
    html = render_markdown("Namespace: `q101-01-example`")
    assert "q101-01-example" in html


def test_split_hint_substitutes_in_both_the_task_and_the_hint():
    question_md = (
        "Namespace: `q101-01-example`\n\n"
        "## Hint\n\nSearch for q101-01-example in the docs.\n"
    )
    task_html, hint_html = split_hint(question_md, "q101-01-example", "alice")
    assert "q101-01-example-alice" in task_html
    assert "q101-01-example-alice" in hint_html


def test_question_context_renders_the_suffixed_namespace_for_a_real_user(
    question_bank_factory, monkeypatch,
):
    bank = question_bank_factory({"topic-a": 1})
    question = bank.questions[0]
    qid = question.id
    (question.path / "QUESTION.md").write_text(
        f"# {qid}\n\n**Namespace:** `{qid}`\n\n"
        f"Run `kubectl get pods -n {qid}`.\n\n## Hint\n\nSearch for `{qid}` too.\n"
    )
    (question.path / "ANSWER.md").write_text(
        f"```sh\nkubectl apply -n {qid} -f manifest.yaml\n```\n"
    )
    monkeypatch.setattr(question_view, "bank", bank)
    monkeypatch.setattr(question_view, "WORK_DIR_ROOT", question.path.parent)

    ctx = question_view.question_context(qid, user_id="alice")

    assert f"{qid}-alice" in ctx["task_html"]
    assert f"{qid}-alice" in ctx["hint_html"]
    assert f"{qid}-alice" in ctx["answer_html"]


def test_question_context_keeps_the_bare_namespace_with_no_accounts(
    question_bank_factory, monkeypatch,
):
    bank = question_bank_factory({"topic-a": 1})
    question = bank.questions[0]
    qid = question.id
    (question.path / "QUESTION.md").write_text(f"# {qid}\n\n**Namespace:** `{qid}`\n")
    (question.path / "ANSWER.md").write_text(f"```sh\nkubectl apply -n {qid} -f manifest.yaml\n```\n")
    monkeypatch.setattr(question_view, "bank", bank)
    monkeypatch.setattr(question_view, "WORK_DIR_ROOT", question.path.parent)

    ctx = question_view.question_context(qid)

    assert f"-n {qid}" in ctx["answer_html"]
