"""question.html's Mermaid <script> tag must stay pinned to an exact
version (I04) - a bare major-version tag like "@10" is a moving target
jsdelivr resolves to whatever the newest 10.x release is at request time,
silently changing behavior on a future upstream release with no diff on
this side to review. Pure string assertion against the template source,
no rendering needed - this is a static asset reference, not template logic.
"""
from __future__ import annotations

import re
from pathlib import Path

TEMPLATE = (Path(__file__).resolve().parent.parent / "templates" / "question.html").read_text()
MERMAID_SRC_RE = re.compile(r'src="https://cdn\.jsdelivr\.net/npm/mermaid@([^/"]+)/dist/mermaid\.min\.js"')


def test_mermaid_script_tag_is_present():
    assert MERMAID_SRC_RE.search(TEMPLATE) is not None


def test_mermaid_is_pinned_to_an_exact_version_not_a_mutable_major_tag():
    match = MERMAID_SRC_RE.search(TEMPLATE)
    version = match.group(1)
    assert re.fullmatch(r"\d+\.\d+\.\d+", version), (
        f"mermaid CDN src is pinned to {version!r}, not an exact major.minor.patch version"
    )
