"""sessions.SessionStore: per-user active-session slots. Used to be a single Optional[ActiveSession] slot shared by
every request; two logged-in accounts must now each get their own slot.
"""
from __future__ import annotations

from sessions import ActiveSession, SessionStore


def _session(mode="fixed", topic="topic-a"):
    return ActiveSession(mode=mode, topic=topic, question_ids=["q1", "q2"])


def test_get_is_none_for_an_unstarted_user():
    store = SessionStore()
    assert store.get("alice") is None


def test_set_active_and_get_round_trip():
    store = SessionStore()
    session = _session()
    store.set_active(session, "alice")
    assert store.get("alice") is session


def test_two_users_have_independent_slots():
    store = SessionStore()
    alice_session = _session(topic="topic-a")
    bob_session = _session(topic="topic-b")
    store.set_active(alice_session, "alice")
    store.set_active(bob_session, "bob")

    assert store.get("alice") is alice_session
    assert store.get("bob") is bob_session


def test_clear_only_affects_that_user():
    store = SessionStore()
    store.set_active(_session(), "alice")
    store.set_active(_session(), "bob")

    store.clear("alice")

    assert store.get("alice") is None
    assert store.get("bob") is not None


def test_none_user_id_is_the_no_accounts_slot():
    # Password gate off / local dev - every caller shares this one key,
    # reproducing the exact single-slot behavior.
    store = SessionStore()
    session = _session()
    store.set_active(session)  # user_id defaults to None
    assert store.get() is session
    assert store.get(None) is session


def test_clear_all_empties_every_users_slot():
    store = SessionStore()
    store.set_active(_session(), "alice")
    store.set_active(_session(), "bob")
    store.set_active(_session())  # None slot too

    store.clear_all()

    assert store.get("alice") is None
    assert store.get("bob") is None
    assert store.get() is None
