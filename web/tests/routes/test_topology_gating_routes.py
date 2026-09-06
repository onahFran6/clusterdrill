"""Regression coverage: route-level proof that the server-derived
node count (bank.set_node_count(), set once at startup from topology.py -
see app.py's lifespan()) actually gates every discovery surface a learner
could reach a question through, not just the questions.py-level filtering
tested directly in tests/test_topology_gating.py.

Surfaces covered here ("Verify a one-node
appliance excludes it from Topics, topic counts, sessions, search surfaces,
and direct routes"):
  - Topics: GET /topics (a whole topic can disappear if every question in
    it needs more nodes than are available).
  - Topic counts / topic-scoped listing: GET /topics/{topic} (a topic that
    still has *some* eligible questions shows a filtered row list and a
    filtered pool_size count).
  - Sessions: POST /sessions/start (a session never draws an ineligible
    question into its pool; a topic with no eligible questions at all is an
    unknown-topic 404, same as a topic that doesn't exist on disk).
  - Direct routes: GET /questions/{qid} (an ineligible qid 404s exactly like
    an unknown qid - services/question_view.get_question_or_404 goes
    through the same bank.get(), so there is no separate "direct link"
    bypass of the topology filter).

There is no dedicated question-search endpoint in this app yet
- topic detail's row listing is the closest existing "browse/discover
questions" surface and is what's covered above as the search-surface
proxy.
"""
from __future__ import annotations


def _wire(question_bank_factory, wire_fake_bank, topic_sizes, min_nodes):
    return wire_fake_bank(question_bank_factory(topic_sizes, min_nodes=min_nodes))


async def test_topics_page_hides_a_topic_whose_whole_pool_needs_two_nodes(
    client, question_bank_factory, wire_fake_bank
):
    bank = _wire(
        question_bank_factory,
        wire_fake_bank,
        {"topic-a": ["easy"], "topic-b": ["easy", "easy"]},
        {"topic-a": 1, "topic-b": 2},
    )

    bank.set_node_count(1)
    res = await client.get("/topics")
    assert res.status_code == 200
    assert "topic-a" in res.text
    assert "topic-b" not in res.text

    bank.set_node_count(2)
    res = await client.get("/topics")
    assert res.status_code == 200
    assert "topic-a" in res.text
    assert "topic-b" in res.text


async def test_topic_detail_excludes_two_node_question_row_and_count(
    client, question_bank_factory, wire_fake_bank
):
    bank = _wire(
        question_bank_factory,
        wire_fake_bank,
        {"topic-a": ["easy", "medium"]},
        {"topic-a": [1, 2]},
    )

    bank.set_node_count(1)
    res = await client.get("/topics/topic-a")
    assert res.status_code == 200
    assert 'href="/questions/qT01-question"' in res.text
    assert 'href="/questions/qT02-question"' not in res.text
    assert "1 total in this topic's pool" in res.text

    bank.set_node_count(2)
    res = await client.get("/topics/topic-a")
    assert res.status_code == 200
    assert 'href="/questions/qT01-question"' in res.text
    assert 'href="/questions/qT02-question"' in res.text
    assert "2 total in this topic's pool" in res.text


async def test_direct_question_route_404s_when_excluded_by_node_count(
    client, question_bank_factory, wire_fake_bank
):
    bank = _wire(
        question_bank_factory,
        wire_fake_bank,
        {"topic-a": ["easy", "medium"]},
        {"topic-a": [1, 2]},
    )

    bank.set_node_count(1)
    res = await client.get("/questions/qT02-question")
    assert res.status_code == 404

    bank.set_node_count(2)
    res = await client.get("/questions/qT02-question")
    assert res.status_code == 200
    assert "qT02-question" in res.text


async def test_session_start_never_draws_a_node_gated_question_into_the_pool(
    client, question_bank_factory, wire_fake_bank
):
    bank = _wire(
        question_bank_factory,
        wire_fake_bank,
        {"topic-a": ["easy", "medium"]},
        {"topic-a": [1, 2]},
    )

    bank.set_node_count(1)
    res = await client.post(
        "/sessions/start",
        data={"mode": "fixed", "topic": "topic-a", "csrf_token": "anything-when-gate-off"},
        follow_redirects=False,
    )
    assert res.status_code == 303
    assert res.headers["location"] == "/questions/qT01-question"

    from sessions import store as session_store

    session = session_store.get()
    assert session.question_ids == ["qT01-question"]
    assert "qT02-question" not in session.question_ids


async def test_session_start_includes_two_node_question_once_node_count_covers_it(
    client, question_bank_factory, wire_fake_bank
):
    bank = _wire(
        question_bank_factory,
        wire_fake_bank,
        {"topic-a": ["easy", "medium"]},
        {"topic-a": [1, 2]},
    )

    bank.set_node_count(2)
    res = await client.post(
        "/sessions/start",
        data={"mode": "fixed", "topic": "topic-a", "csrf_token": "anything-when-gate-off"},
        follow_redirects=False,
    )
    assert res.status_code == 303

    from sessions import store as session_store

    session = session_store.get()
    assert set(session.question_ids) == {"qT01-question", "qT02-question"}


async def test_session_start_404s_for_a_topic_entirely_gated_out_by_node_count(
    client, question_bank_factory, wire_fake_bank
):
    # A topic whose only question needs 2 nodes is indistinguishable from an
    # unknown topic on a one-node appliance - both are "not in bank.topics()"
    # - matching the plain 404 an unknown topic name already gets.
    bank = _wire(
        question_bank_factory, wire_fake_bank, {"topic-c": ["hard"]}, {"topic-c": 2}
    )

    bank.set_node_count(1)
    res = await client.post(
        "/sessions/start",
        data={"mode": "fixed", "topic": "topic-c", "csrf_token": "anything-when-gate-off"},
    )
    assert res.status_code == 404

    bank.set_node_count(2)
    res = await client.post(
        "/sessions/start",
        data={"mode": "fixed", "topic": "topic-c", "csrf_token": "anything-when-gate-off"},
        follow_redirects=False,
    )
    assert res.status_code == 303
