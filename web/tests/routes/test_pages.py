"""Route-level tests for routers/pages.py + routers/health.py, against the
real FastAPI app via httpx.ASGITransport - no real cluster/tmux/ttyd (see
tests/conftest.py's autouse safety net; profile_store/bank are mocked via
tests/routes/conftest.py's fixtures)."""
from __future__ import annotations


async def test_index_redirects_to_topics(client):
    res = await client.get("/", follow_redirects=False)
    assert res.status_code in (302, 307)
    assert res.headers["location"] == "/topics"


async def test_topics_page_lists_every_topic(client, fake_bank):
    res = await client.get("/topics")
    assert res.status_code == 200
    assert "topic-a" in res.text
    assert "topic-b" in res.text


async def test_topics_page_includes_csrf_meta_tag(client, fake_bank):
    res = await client.get("/topics")
    assert 'name="csrf-token"' in res.text


async def test_topics_page_shows_locked_daily_challenge_by_default(client, fake_bank):
    # fake_profile (autouse) stubs has_achievement to False - no "cleared
    # today" badge should render.
    res = await client.get("/topics")
    assert "Daily challenge" in res.text
    assert "cleared today" not in res.text


async def test_topics_page_shows_cleared_daily_challenge(client, fake_bank, monkeypatch):
    import profile_store
    monkeypatch.setattr(profile_store, "has_achievement", lambda name, user_id=None: True)
    res = await client.get("/topics")
    assert "cleared today" in res.text


async def test_topic_detail_unknown_topic_is_404(client, fake_bank):
    res = await client.get("/topics/does-not-exist")
    assert res.status_code == 404


async def test_topic_detail_known_topic_200(client, fake_bank):
    res = await client.get("/topics/topic-a")
    assert res.status_code == 200


# --- GPL-3.0 community-content badge ------------------------------------

async def test_topics_page_no_gpl_badge_for_ordinary_topics(client, fake_bank):
    res = await client.get("/topics")
    assert "GPL-3.0" not in res.text


async def test_topics_page_shows_gpl_badge_for_community_topic(client, question_bank_factory, wire_fake_bank):
    wire_fake_bank(question_bank_factory({"community": 2, "topic-a": 2}))
    res = await client.get("/topics")
    assert "GPL-3.0" in res.text


async def test_topic_detail_no_gpl_badge_for_ordinary_topic(client, fake_bank):
    res = await client.get("/topics/topic-a")
    assert "GPL-3.0" not in res.text


async def test_topic_detail_shows_gpl_badge_for_community_topic(client, question_bank_factory, wire_fake_bank):
    wire_fake_bank(question_bank_factory({"community": 2}))
    res = await client.get("/topics/community")
    assert "GPL-3.0" in res.text


async def test_practice_tests_page_200(client, fake_bank):
    res = await client.get("/practice-tests")
    assert res.status_code == 200


async def test_practice_tests_page_shows_empty_state_for_zero_topics(client, question_bank_factory, wire_fake_bank):
    wire_fake_bank(question_bank_factory({}))
    res = await client.get("/practice-tests")
    assert "No practice sets available yet." in res.text
    assert res.text.count('class="kget-row"') == 0


async def test_topics_page_kget_table_renders_via_shared_macros(client, fake_bank):
    """Regression test for the topics.html/practice_tests.html macro
    migration (kget_table_head/kget_row/kget_col in _macros.html) -
    proves the call-block refactor actually renders the expected column
    headers and per-topic rows through the real route, not just in a
    macro-level unit test."""
    res = await client.get("/topics")
    assert '<span class="kget-col kget-col-name" role="columnheader">Name</span>' in res.text
    assert '<span class="kget-col kget-col-name" role="cell">' in res.text
    assert res.text.count('class="kget-row"') == 2  # topic-a, topic-b


async def test_progress_page_200(client, fake_bank):
    res = await client.get("/progress")
    assert res.status_code == 200


async def test_mock_exam_page_200(client, fake_bank):
    res = await client.get("/mock-exam")
    assert res.status_code == 200


async def test_mock_exam_page_renders_the_exam_setup_form(client, fake_bank):
    # The exam setup form: topic + difficulty checkboxes (default all
    # checked), a question-count select, a timer select, posting mode=exam.
    res = await client.get("/mock-exam")
    assert 'name="mode" value="exam"' in res.text
    assert 'name="topics" value="topic-a" checked' in res.text
    assert 'name="topics" value="topic-b" checked' in res.text
    assert 'name="difficulties" value="easy" checked' in res.text
    assert 'name="difficulties" value="medium" checked' in res.text
    assert 'name="difficulties" value="hard" checked' in res.text
    assert 'name="question_count"' in res.text
    assert 'name="timer_minutes"' in res.text


async def test_mock_exam_page_shows_resume_banner_for_an_active_exam_session(client, fake_bank):
    start_res = await client.post(
        "/sessions/start",
        data={"mode": "exam", "csrf_token": "x"},
        follow_redirects=False,
    )
    assert start_res.status_code == 303

    res = await client.get("/mock-exam")
    assert "already running" in res.text
    assert 'name="mode" value="exam"' not in res.text  # setup form is hidden while one's active


async def test_healthz_reports_question_count(client, fake_bank):
    res = await client.get("/healthz")
    assert res.status_code == 200
    # excluded_question_count is always 0 here: fake_bank
    # never calls set_node_count(), so nothing is filtered out.
    assert res.json() == {"ok": True, "question_count": 4, "excluded_question_count": 0}
