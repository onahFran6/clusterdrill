"""services/question_view.py's auto-provision cache, keyed by (qid, user_id).
Two different users viewing the same
question must each trigger their own setup.sh run (their own namespace),
not share one process-lifetime "already provisioned" flag - the bug this
phase would otherwise introduce (a second user's first view silently
skipping provisioning because *someone else* already viewed that qid).

profile_store.get_profile()/session_store are mocked the same way
tests/routes/conftest.py's fake_profile fixture does for route tests - this
file calls question_context() directly rather than through a route, so it
needs the same mocking done by hand.
"""
from __future__ import annotations

from unittest.mock import MagicMock

import node_topology
import profile_store
import pytest
import services.question_view as question_view
from grading_client import ResetResult
from sessions import store as session_store


@pytest.fixture(autouse=True)
def _isolate_module_globals(monkeypatch, tmp_path):
    """Same reasoning as tests/routes/conftest.py's _clean_session_store/
    fake_profile/_isolate_workdir_root - question_context() touches
    process-wide singletons this test must not leak into (or be polluted
    by) other tests. node_topology.get_topology() (issue #122) is a real
    `kubectl get nodes` call otherwise - mocked here for the same reason
    profile_store.get_profile is, not because this file cares about node
    topology at all."""
    question_view._auto_provisioned_qids.clear()
    monkeypatch.setattr(question_view, "WORK_DIR_ROOT", tmp_path / "practice-work")
    empty_profile = profile_store.Profile(spec=dict(profile_store._EMPTY_PROFILE_SPEC))
    monkeypatch.setattr(profile_store, "get_profile", lambda user_id=None: empty_profile)
    monkeypatch.setattr(node_topology, "get_topology", lambda **kw: node_topology._EMPTY)
    session_store.clear()
    yield
    question_view._auto_provisioned_qids.clear()
    session_store.clear()


@pytest.fixture
def one_question_bank(question_bank_factory, monkeypatch):
    bank = question_bank_factory({"topic-a": 1})
    question = bank.questions[0]
    (question.path / "setup.sh").write_text("#!/usr/bin/env bash\necho ok\n")
    monkeypatch.setattr(question_view, "bank", bank)
    return question.id


@pytest.fixture
def mock_run_setup(monkeypatch):
    mock = MagicMock(return_value=ResetResult(ok=True, output=""))
    monkeypatch.setattr(question_view, "run_setup", mock)
    return mock


def test_auto_provision_runs_once_per_qid_for_the_same_user(one_question_bank, mock_run_setup):
    qid = one_question_bank
    question_view.question_context(qid, user_id="alice")
    question_view.question_context(qid, user_id="alice")
    mock_run_setup.assert_called_once()


def test_auto_provision_runs_separately_per_user(one_question_bank, mock_run_setup):
    qid = one_question_bank
    question_view.question_context(qid, user_id="alice")
    question_view.question_context(qid, user_id="bob")

    assert mock_run_setup.call_count == 2
    called_user_ids = {kwargs.get("user_id") for _, kwargs in mock_run_setup.call_args_list}
    assert called_user_ids == {"alice", "bob"}


def test_auto_provision_runs_once_with_no_accounts(one_question_bank, mock_run_setup):
    # Password gate off / no accounts: user_id is always None for
    # every call - still only provisions once.
    qid = one_question_bank
    question_view.question_context(qid)
    question_view.question_context(qid)
    mock_run_setup.assert_called_once_with(question_view.get_question_or_404(qid).setup_sh, user_id=None)


def test_provision_error_is_none_when_setup_succeeds(one_question_bank, mock_run_setup):
    qid = one_question_bank
    ctx = question_view.question_context(qid, user_id="alice")
    assert ctx["provision_error"] is None


def test_a_failed_setup_run_is_retried_on_the_next_view(one_question_bank, monkeypatch):
    # issue #95's secondary finding: a transient setup.sh failure (cluster
    # hiccup, RBAC race, SETUP_TIMEOUT_SECONDS) used to permanently mark
    # (qid, user_id) as provisioned, so it was never retried and the failure
    # was only ever visible in a server-side log line.
    qid = one_question_bank
    mock = MagicMock(side_effect=[
        ResetResult(ok=False, output="", error="cluster unreachable"),
        ResetResult(ok=True, output=""),
    ])
    monkeypatch.setattr(question_view, "run_setup", mock)

    first = question_view.question_context(qid, user_id="alice")
    assert first["provision_error"] == "cluster unreachable"
    assert (qid, "alice") not in question_view._auto_provisioned_qids

    second = question_view.question_context(qid, user_id="alice")
    assert second["provision_error"] is None
    assert mock.call_count == 2
