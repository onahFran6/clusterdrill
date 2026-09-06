"""Resolves the appliance image `local install` uses when `--image` is omitted.

Maps an installed `clusterdrill` package version to the immutable image
digest a release pipeline published for it, via `RELEASE_MANIFEST_PATH`
(package-data updated per published version). See README.md's "Release
policy" section for what this means in practice today: a real image was
published once, early in this project's history, before several naming
and architecture changes landed - it no longer reflects the current
source tree, so `local install` without `--image` resolves it anyway
(it's what this module is for), but the documented Quick start tells
operators to pass `--image clusterdrill:dev` instead until a release
matching current source exists.
"""
from __future__ import annotations

import json
from importlib import metadata
from pathlib import Path

PACKAGE_NAME = "clusterdrill"
DEV_IMAGE = "clusterdrill:dev"
# docker.io/w00dson/clusterdrill (public), created
# 2026-09-04. Not used until RELEASE_MANIFEST_PATH has a digest to pair it
# with - see the release GitHub Actions workflow (.github/workflows/release-image.yml).
RELEASE_REPOSITORY = "docker.io/w00dson/clusterdrill"
RELEASE_MANIFEST_PATH = Path(__file__).with_name("release_manifest.json")


def installed_version() -> str | None:
    try:
        return metadata.version(PACKAGE_NAME)
    except metadata.PackageNotFoundError:
        return None


def _release_digests() -> dict[str, str]:
    if not RELEASE_MANIFEST_PATH.is_file():
        return {}
    data = json.loads(RELEASE_MANIFEST_PATH.read_text())
    return data.get("digests", {})


def resolve_default_image(version: str | None = None) -> str:
    """Return the release-pinned image for `version`, or the dev fallback.

    `version` defaults to the installed `clusterdrill` package version.
    Falls back to `DEV_IMAGE` whenever no version is resolvable (running
    from a source checkout, not an installed package) or the release
    manifest has no digest recorded for that version.
    """
    if version is None:
        version = installed_version()
    digest = _release_digests().get(version) if version else None
    if not digest:
        return DEV_IMAGE
    return f"{RELEASE_REPOSITORY}@{digest}"
