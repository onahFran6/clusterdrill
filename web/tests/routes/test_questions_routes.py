"""Route-level tests for routers/questions_router.py.

run_check/run_reset are always mocked - never let a real check.sh/setup.sh
run against the real cluster/lib/grading.sh (see
tests/routes/test_sessions_routes.py's module docstring for the same
concern re: run_batch_cleanup). Fixture questions (question_bank_factory)
never have a setup.sh, so question_context()'s auto-provision path and
reset's "setup.sh missing" branch are both exercised for free, safely, by
construction - no mocking needed for those specifically.
"""
from __future__ import annotations

from unittest.mock import MagicMock

import profile_store
import routers.questions_router as questions_router
import services.question_view as question_view
from grading_client import CheckResult, Criterion, ResetResult
from profile_store import CheckRecordResult, Profile
from sessions import BOSS_DAMAGE_SLOW_PASS, BOSS_DAMAGE_WRONG_CHECK, BOSS_MAX_HP, ActiveSession
from sessions import store as session_store


async def test_view_known_question_200(client, fake_bank):
    res = await client.get("/questions/qT01-question")
    assert res.status_code == 200
    assert "qT01-question" in res.text


# --- Question navigator ------------------------------------------------

async def test_question_page_renders_a_navigator_item_per_session_question(
    client, question_bank_factory, wire_fake_bank,
):
    bank = wire_fake_bank(question_bank_factory({"topic-a": 3}))
    qids = [q.id for q in bank.questions]
    session_store.set_active(ActiveSession(mode="fixed", topic="topic-a", question_ids=qids))

    res = await client.get(f"/questions/{qids[1]}")

    assert res.text.count("question-navigator-item") == 3
    assert f'href="/questions/{qids[1]}"' in res.text
    assert 'class="question-navigator-item status-visited current"' in res.text


async def test_question_page_has_no_navigator_outside_a_session(client, fake_bank):
    res = await client.get("/questions/qT01-question")
    assert "question-navigator" not in res.text


async def test_view_unknown_question_404(client, fake_bank):
    res = await client.get("/questions/not-a-real-qid")
    assert res.status_code == 404


async def test_view_question_bad_tab_falls_back_to_task(client, fake_bank):
    res = await client.get("/questions/qT01-question?tab=nonsense")
    assert res.status_code == 200


async def test_view_question_surfaces_a_failed_auto_provision(
    client, question_bank_factory, wire_fake_bank, monkeypatch,
):
    # Unlike this module's other tests (see module docstring), this one
    # question needs a real setup.sh so question_context()'s auto-provision
    # path actually runs - run_setup itself is still mocked, exactly like
    # test_question_view_auto_provision.py, so no real subprocess/cluster
    # call happens. Exercises the full route -> template render (issue #95's
    # question.html alert), not just the context dict question_view.py's own
    # unit tests already cover.
    bank = wire_fake_bank(question_bank_factory({"topic-a": 1}))
    question = bank.questions[0]
    (question.path / "setup.sh").write_text("#!/usr/bin/env bash\necho ok\n")
    monkeypatch.setattr(
        question_view,
        "run_setup",
        lambda *a, **k: ResetResult(ok=False, output="", error="cluster unreachable"),
    )
    question_view._auto_provisioned_qids.clear()

    res = await client.get(f"/questions/{question.id}")

    assert res.status_code == 200
    assert "cluster unreachable" in res.text
    assert 'id="provision-error"' in res.text

    question_view._auto_provisioned_qids.clear()


async def test_check_unknown_question_404(client, fake_bank):
    res = await client.post("/questions/not-a-real-qid/check", json={})
    assert res.status_code == 404


# --- GPL-3.0 community-content badge ------------------------------------

async def test_view_question_no_gpl_badge_for_ordinary_topic(client, fake_bank):
    res = await client.get("/questions/qT01-question")
    assert "GPL-3.0" not in res.text


async def test_view_question_shows_gpl_badge_for_community_topic(client, question_bank_factory, wire_fake_bank):
    wire_fake_bank(question_bank_factory({"community": 1}))
    res = await client.get("/questions/qC01-question")
    assert "GPL-3.0" in res.text


async def test_check_runs_and_records_result(client, fake_bank, monkeypatch):
    fake_result = CheckResult(
        criteria=[Criterion(description="pod exists", passed=True)],
        passed=1, total=1, raw_stdout="", raw_stderr="", ok=True, error=None,
    )
    monkeypatch.setattr(questions_router, "run_check", lambda path, user_id=None: fake_result)

    fake_record = CheckRecordResult(
        profile=Profile(spec={"xp": 10, "questions": {"qT01-question": {"bestTimeMs": 4200, "bestSpeedTier": "gold"}}}),
        first_clear=True,
        new_achievements=["no-hints-qT01-question"],
        speed_tier="gold",
    )
    mock_record_check = MagicMock(return_value=fake_record)
    import profile_store
    monkeypatch.setattr(profile_store, "record_check", mock_record_check)

    res = await client.post(
        "/questions/qT01-question/check",
        json={"elapsed_ms": 4200, "used_hint": False},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["passed"] == 1
    assert data["total"] == 1
    assert data["ok"] is True
    assert data["criteria"] == [{"description": "pod exists", "passed": True}]
    assert data["profile_xp"] == 10
    assert data["new_achievements"] == ["no-hints-qT01-question"]
    assert data["speed_tier"] == "gold"
    assert data["profile_best_speed_tier"] == "gold"
    mock_record_check.assert_called_once()


def _mock_check(monkeypatch, passed, total, speed_tier=None):
    fake_result = CheckResult(
        criteria=[Criterion(description="c", passed=passed == total)],
        passed=passed, total=total, raw_stdout="", raw_stderr="", ok=True, error=None,
    )
    monkeypatch.setattr(questions_router, "run_check", lambda path, user_id=None: fake_result)
    fake_record = CheckRecordResult(
        profile=Profile(spec={"xp": 0, "questions": {}}),
        first_clear=False,
        new_achievements=[],
        speed_tier=speed_tier,
    )
    monkeypatch.setattr(profile_store, "record_check", MagicMock(return_value=fake_record))
    # A full clear can fire apply_clean_sweep/apply_boss_defeat, both of
    # which shell out to real kubectl (profile_store.apply_achievement) -
    # never let that happen for real in a route test, same reasoning as
    # every other kubectl-touching call mocked in this file/conftest.
    monkeypatch.setattr(profile_store, "apply_achievement", MagicMock())


# --- boss mini-exam HP/win ------------------------------------------

async def test_check_boss_session_wrong_answer_damages_hp(client, fake_bank, monkeypatch):
    _mock_check(monkeypatch, passed=0, total=1)
    session_store.set_active(ActiveSession(mode="boss", topic="topic-a", question_ids=["qT01-question"]))

    res = await client.post("/questions/qT01-question/check", json={"elapsed_ms": 1000, "used_hint": False})
    assert res.status_code == 200
    data = res.json()
    assert data["boss_hp"] == BOSS_MAX_HP - BOSS_DAMAGE_WRONG_CHECK
    assert data["boss_max_hp"] == BOSS_MAX_HP
    assert data["boss_won"] is False


async def test_check_boss_session_slow_pass_damages_hp_less(client, fake_bank, monkeypatch):
    _mock_check(monkeypatch, passed=1, total=1, speed_tier=None)
    session_store.set_active(
        ActiveSession(mode="boss", topic="topic-a", question_ids=["qT01-question", "qT02-question"])
    )

    res = await client.post("/questions/qT01-question/check", json={"elapsed_ms": 999999, "used_hint": False})
    assert res.status_code == 200
    data = res.json()
    assert data["boss_hp"] == BOSS_MAX_HP - BOSS_DAMAGE_SLOW_PASS
    assert data["boss_won"] is False  # only 1 of 2 boss questions passed


async def test_check_boss_session_fast_pass_no_damage(client, fake_bank, monkeypatch):
    _mock_check(monkeypatch, passed=1, total=1, speed_tier="gold")
    session_store.set_active(ActiveSession(mode="boss", topic="topic-a", question_ids=["qT01-question"]))

    res = await client.post("/questions/qT01-question/check", json={"elapsed_ms": 100, "used_hint": False})
    data = res.json()
    assert data["boss_hp"] == BOSS_MAX_HP
    assert data["boss_won"] is True


async def test_check_boss_session_no_win_once_hp_hits_zero(client, fake_bank, monkeypatch):
    session_store.set_active(
        ActiveSession(mode="boss", topic="topic-a", question_ids=["qT01-question"], hp=BOSS_DAMAGE_WRONG_CHECK)
    )
    _mock_check(monkeypatch, passed=0, total=1)
    res = await client.post("/questions/qT01-question/check", json={"elapsed_ms": 1000, "used_hint": False})
    assert res.json()["boss_hp"] == 0

    # A second, passing Check can't win the fight anymore - HP already hit 0.
    _mock_check(monkeypatch, passed=1, total=1, speed_tier="gold")
    res = await client.post("/questions/qT01-question/check", json={"elapsed_ms": 100, "used_hint": False})
    data = res.json()
    assert data["boss_hp"] == 0
    assert data["boss_won"] is False


async def test_check_non_boss_session_omits_boss_fields(client, fake_bank, monkeypatch):
    _mock_check(monkeypatch, passed=1, total=1, speed_tier="gold")
    session_store.set_active(ActiveSession(mode="fixed", topic="topic-a", question_ids=["qT01-question"]))

    res = await client.post("/questions/qT01-question/check", json={"elapsed_ms": 100, "used_hint": False})
    data = res.json()
    assert data["boss_hp"] is None
    assert data["boss_max_hp"] is None
    assert data["boss_won"] is False


# --- daily/session mixed challenge award ---------------------------

async def test_check_daily_session_full_clear_applies_achievement(client, fake_bank, monkeypatch):
    _mock_check(monkeypatch, passed=1, total=1, speed_tier="gold")
    mock_apply = MagicMock()
    monkeypatch.setattr(profile_store, "apply_daily_challenge_clear", mock_apply)
    session_store.set_active(ActiveSession(mode="daily", topic=None, question_ids=["qT01-question"]))

    res = await client.post("/questions/qT01-question/check", json={"elapsed_ms": 100, "used_hint": False})
    assert res.status_code == 200
    mock_apply.assert_called_once()
    # First positional/keyword arg is the date string - just check a call
    # happened with *a* user_id kwarg, not the exact date (which is
    # today's real UTC date, not worth freezing time to assert on here).
    assert mock_apply.call_args.kwargs.get("user_id") is None


async def test_check_daily_session_partial_clear_does_not_apply_achievement(client, fake_bank, monkeypatch):
    _mock_check(monkeypatch, passed=1, total=1, speed_tier="gold")
    mock_apply = MagicMock()
    monkeypatch.setattr(profile_store, "apply_daily_challenge_clear", mock_apply)
    session_store.set_active(
        ActiveSession(mode="daily", topic=None, question_ids=["qT01-question", "qT02-question"])
    )

    res = await client.post("/questions/qT01-question/check", json={"elapsed_ms": 100, "used_hint": False})
    assert res.status_code == 200
    mock_apply.assert_not_called()


async def test_check_daily_session_omits_boss_fields(client, fake_bank, monkeypatch):
    _mock_check(monkeypatch, passed=1, total=1, speed_tier="gold")
    session_store.set_active(ActiveSession(mode="daily", topic=None, question_ids=["qT01-question"]))

    res = await client.post("/questions/qT01-question/check", json={"elapsed_ms": 100, "used_hint": False})
    data = res.json()
    assert data["boss_hp"] is None
    assert data["boss_won"] is False


# --- Exam session status-bar badge ------------------
# topic=None used to mean *only* "every topic, unconditionally" (Mixed/
# Daily) - exam mode is the first case where it can also mean "a
# candidate-chosen subset", which the plain "all topics" fallback would
# otherwise misreport (services/question_view.py's question_context()).

async def test_exam_session_badge_shows_a_topic_count_when_narrowed(client, question_bank_factory, wire_fake_bank):
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 3, "beta-topic": 3}))
    alpha_qids = [q.id for q in bank.questions if q.topic == "alpha-topic"]
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=alpha_qids))

    res = await client.get(f"/questions/{alpha_qids[0]}")
    assert "1 topics" in res.text
    assert "all topics" not in res.text


async def test_exam_session_badge_shows_all_topics_when_not_narrowed(client, question_bank_factory, wire_fake_bank):
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 3, "beta-topic": 3}))
    all_qids = [q.id for q in bank.questions]
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=all_qids))

    res = await client.get(f"/questions/{all_qids[0]}")
    assert "all topics" in res.text


async def test_reset_without_setup_sh_is_500(client, fake_bank):
    # Fixture questions never ship a setup.sh (see module docstring) - the
    # route's own "setup.sh missing" guard should fire before run_reset is
    # ever reached, which is exactly what keeps this test safe without
    # mocking run_reset.
    res = await client.post("/questions/qT01-question/reset")
    assert res.status_code == 500
    assert "setup.sh" in res.json()["detail"]


async def test_reset_unknown_question_404(client, fake_bank):
    res = await client.post("/questions/not-a-real-qid/reset")
    assert res.status_code == 404


# --- Deferred grading during an exam session --------

async def test_exam_session_question_page_has_no_check_button_or_checklist(client, fake_bank):
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=["qT01-question"]))

    res = await client.get("/questions/qT01-question")

    assert 'id="check-btn"' not in res.text
    assert 'id="criteria-list"' not in res.text
    assert "graded at once when you submit" in res.text


async def test_exam_session_question_page_hides_the_solution_tab(client, fake_bank):
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=["qT01-question"]))

    res = await client.get("/questions/qT01-question")

    assert 'data-tab="solution"' not in res.text


async def test_exam_session_requesting_the_solution_tab_falls_back_to_task(client, fake_bank):
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=["qT01-question"]))

    res = await client.get("/questions/qT01-question?tab=solution")

    assert res.status_code == 200
    assert 'data-tab="task"' in res.text


async def test_exam_session_question_page_still_has_reset(client, fake_bank):
    # Deferred grading only removes grading feedback - resetting your own
    # environment is unrelated and stays available. fake_bank's questions
    # never ship a setup.sh (module docstring), so Reset is absent for
    # that reason regardless of mode - prove it's absent for *that* reason
    # here, not because exam mode removes it too, by giving this one
    # question a setup.sh and confirming Reset reappears.
    question = fake_bank.get("qT01-question")
    question.path.joinpath("setup.sh").write_text("#!/usr/bin/env bash\necho ok\n")
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=["qT01-question"]))

    res = await client.get("/questions/qT01-question")

    assert 'id="reset-btn"' in res.text


async def test_non_exam_session_question_page_still_has_check_button_and_solution_tab(client, fake_bank):
    session_store.set_active(ActiveSession(mode="fixed", topic="topic-a", question_ids=["qT01-question"]))

    res = await client.get("/questions/qT01-question")

    assert 'id="check-btn"' in res.text
    assert 'data-tab="solution"' in res.text
