"""services/question_view.base_context: is_admin_hint gating (I04).

Regression test for a confirmed bug: the bootstrap admin account's session
still carries IS_ADMIN_KEY=True under single-user mode (it's simply the one
account that mode allows), but admin_router.admin_page always 404s in that
mode regardless of who's asking - the Admin nav link must not be shown if
it can only ever lead to a dead end.
"""
from __future__ import annotations

import auth
import services.question_view as question_view
import users


class FakeRequest:
    """Minimal stand-in for starlette.requests.Request - base_context only
    ever touches .session, same minimal surface as tests/test_auth.py's own
    FakeRequest."""

    def __init__(self, session: dict):
        self.session = session


def test_is_admin_hint_true_for_admin_outside_single_user_mode(monkeypatch):
    monkeypatch.setattr(users, "single_user_mode", lambda: False)
    request = FakeRequest({auth.IS_ADMIN_KEY: True})
    assert question_view.base_context(request)["is_admin_hint"] is True


def test_is_admin_hint_false_in_single_user_mode_even_for_the_admin_account(monkeypatch):
    monkeypatch.setattr(users, "single_user_mode", lambda: True)
    request = FakeRequest({auth.IS_ADMIN_KEY: True})
    assert question_view.base_context(request)["is_admin_hint"] is False


def test_is_admin_hint_false_for_non_admin(monkeypatch):
    monkeypatch.setattr(users, "single_user_mode", lambda: False)
    request = FakeRequest({auth.IS_ADMIN_KEY: False})
    assert question_view.base_context(request)["is_admin_hint"] is False
