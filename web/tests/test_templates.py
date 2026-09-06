"""Template-level regression tests for logic embedded directly in Jinja2
templates (not exercised by a route - these render the template directly).
"""
from __future__ import annotations

import re

import pytest
from jinja2 import Environment, FileSystemLoader
from templating import WEB_DIR

_env = Environment(loader=FileSystemLoader(str(WEB_DIR / "templates")))
_TEMPLATES_DIR = WEB_DIR / "templates"


@pytest.mark.parametrize("lockout_seconds,expected_minutes,expected_word", [
    (1, 1, "minute"),
    (60, 1, "minute"),
    (61, 2, "minutes"),   # ceil(61/60) = 2 - previously showed "2 minute" (wrong)
    (120, 2, "minutes"),
    (900, 15, "minutes"),
])
def test_login_lockout_message_pluralizes_the_displayed_minute_count(
    lockout_seconds, expected_minutes, expected_word
):
    html = _env.get_template("login.html").render(
        next="/topics", error=True, lockout_seconds=lockout_seconds, csrf_token=""
    )
    assert f"Try again in {expected_minutes} {expected_word}." in html


def _render_macro(source: str, **context) -> str:
    """Render a snippet that imports _macros.html as `m`, e.g.
    "{{ m.pill('x') }}" - lets macro tests assert on output directly
    without needing a full page's route context."""
    template = _env.from_string('{% import "_macros.html" as m %}' + source)
    return template.render(**context)


class TestPillMacro:
    def test_plain(self):
        assert _render_macro("{{ m.pill('easy') }}") == '<span class="pill">easy</span>'

    def test_with_variant(self):
        assert (
            _render_macro("{{ m.pill('easy', 'easy') }}")
            == '<span class="pill pill-easy">easy</span>'
        )

    def test_with_title(self):
        html = _render_macro("{{ m.pill('GPL-3.0', 'community', 'ported content') }}")
        assert html == '<span class="pill pill-community" title="ported content">GPL-3.0</span>'

    def test_with_style(self):
        html = _render_macro("{{ m.pill('cleared today', style='color: var(--pass);') }}")
        assert html == '<span class="pill" style="color: var(--pass);">cleared today</span>'


class TestKgetHeroMacro:
    def test_renders_the_given_command(self):
        html = _render_macro("{{ m.kget_hero('kubectl get topiclabs -o wide') }}")
        assert 'class="kget-hero"' in html
        assert "kubectl get topiclabs -o wide" in html


class TestQuestionStatusMacro:
    @pytest.mark.parametrize("status,expected_class,expected_glyph", [
        ("correct", "pass", "[&check;]"),
        ("incorrect", "fail", "[&cross;]"),
        ("partial", "warn", "[!]"),
        ("pending", "unanswered", "[&nbsp;]"),
        ("anything-else-falls-through-to-unanswered", "unanswered", "[&nbsp;]"),
    ])
    def test_status_maps_to_class_and_glyph(self, status, expected_class, expected_glyph):
        html = _render_macro("{{ m.question_status(status) }}", status=status)
        assert f'question-row-mark {expected_class}' in html
        assert expected_glyph in html


class TestKgetTableMacros:
    def test_table_head_renders_one_column_header_per_entry(self):
        html = _render_macro(
            "{{ m.kget_table_head([('name', 'Name'), ('pool', 'Pool')]) }}"
        )
        assert 'role="row"' in html
        assert 'class="kget-col kget-col-name" role="columnheader">Name</span>' in html
        assert 'class="kget-col kget-col-pool" role="columnheader">Pool</span>' in html

    def test_row_and_col_wrap_caller_content(self):
        html = _render_macro(
            "{% call m.kget_row() %}{% call m.kget_col('name') %}hello{% endcall %}{% endcall %}"
        )
        assert '<div class="kget-row" role="row">' in html
        assert '<span class="kget-col kget-col-name" role="cell">hello</span>' in html


# issue #96: product copy citing this repo's own internal planning doc or a
# ticket/section id reads like an engineering note, not product copy, and
# some of it was shown to unauthenticated visitors (the login page). HTML
# (<!-- -->) and Jinja ({# #}) comments never reach the browser, so they're
# stripped before checking - only text that would actually render counts.
_HTML_COMMENT_RE = re.compile(r"<!--.*?-->", re.DOTALL)
_JINJA_COMMENT_RE = re.compile(r"\{#.*?#\}", re.DOTALL)
_INTERNAL_CITATION_RE = re.compile(r"PLAN\.md|IMPLEMENTATION\.md|§\s*\d")


def test_no_template_renders_a_citation_of_an_internal_doc_or_ticket():
    offenders = []
    for path in sorted(_TEMPLATES_DIR.glob("*.html")):
        rendered_text = _JINJA_COMMENT_RE.sub("", _HTML_COMMENT_RE.sub("", path.read_text()))
        if _INTERNAL_CITATION_RE.search(rendered_text):
            offenders.append(path.name)
    assert not offenders, f"internal doc/ticket citation would render in: {offenders}"
