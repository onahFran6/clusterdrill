"""clusterdrill/release.py: resolves the release-pinned image `local install`
defaults to, falling back to the local development image whenever the
installed version has no published digest - true for every version today,
since no release has been published yet.
"""
from __future__ import annotations

import json
from importlib import metadata

import pytest

from clusterdrill import release


def test_resolve_default_image_falls_back_to_dev_when_manifest_has_no_entry(monkeypatch, tmp_path):
    manifest_path = tmp_path / "release_manifest.json"
    manifest_path.write_text(json.dumps({"digests": {}}))
    monkeypatch.setattr(release, "RELEASE_MANIFEST_PATH", manifest_path)

    assert release.resolve_default_image(version="1.2.3") == release.DEV_IMAGE


def test_resolve_default_image_falls_back_to_dev_when_manifest_file_missing(monkeypatch, tmp_path):
    monkeypatch.setattr(release, "RELEASE_MANIFEST_PATH", tmp_path / "does-not-exist.json")

    assert release.resolve_default_image(version="1.2.3") == release.DEV_IMAGE


def test_resolve_default_image_falls_back_to_dev_when_version_unresolvable(monkeypatch, tmp_path):
    manifest_path = tmp_path / "release_manifest.json"
    manifest_path.write_text(json.dumps({"digests": {"1.2.3": "sha256:" + "a" * 64}}))
    monkeypatch.setattr(release, "RELEASE_MANIFEST_PATH", manifest_path)
    monkeypatch.setattr(release, "installed_version", lambda: None)

    assert release.resolve_default_image() == release.DEV_IMAGE


def test_resolve_default_image_uses_release_manifest_digest_when_present(monkeypatch, tmp_path):
    digest = "sha256:" + "b" * 64
    manifest_path = tmp_path / "release_manifest.json"
    manifest_path.write_text(json.dumps({"digests": {"1.2.3": digest}}))
    monkeypatch.setattr(release, "RELEASE_MANIFEST_PATH", manifest_path)

    image = release.resolve_default_image(version="1.2.3")

    assert image == f"{release.RELEASE_REPOSITORY}@{digest}"
    assert "@sha256:" in image


def test_resolve_default_image_uses_installed_version_when_none_given(monkeypatch, tmp_path):
    digest = "sha256:" + "c" * 64
    manifest_path = tmp_path / "release_manifest.json"
    manifest_path.write_text(json.dumps({"digests": {"9.9.9": digest}}))
    monkeypatch.setattr(release, "RELEASE_MANIFEST_PATH", manifest_path)
    monkeypatch.setattr(release, "installed_version", lambda: "9.9.9")

    assert release.resolve_default_image() == f"{release.RELEASE_REPOSITORY}@{digest}"


def test_installed_version_returns_none_when_package_not_installed(monkeypatch):
    def raise_not_found(_name):
        raise metadata.PackageNotFoundError()

    monkeypatch.setattr(release.metadata, "version", raise_not_found)

    assert release.installed_version() is None


def test_installed_version_returns_metadata_version(monkeypatch):
    monkeypatch.setattr(release.metadata, "version", lambda name: "1.2.3" if name == release.PACKAGE_NAME else pytest.fail("wrong package name"))

    assert release.installed_version() == "1.2.3"
