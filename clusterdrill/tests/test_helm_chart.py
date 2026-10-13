"""Static checks that clusterdrill/helm/clusterdrill-chart (the optional Helm
install path) is RBAC- and shape-equivalent to
clusterdrill/manifests/local-appliance.yaml (the primary, baseline
manifest path) - same approach as test_manifest.py's own checks, applied
to `helm template`'s rendered output via a real `helm` subprocess (no
cluster needed, matches this directory's neighbors: no live cluster
involved, just parsing rendered/static YAML).

These tests guard the shape of the chart going forward, the same way
test_manifest.py's own docstring already says its checks do for the raw
manifest - they do not replace the still-outstanding human security
review of the RBAC contract itself, which applies equally to both
install paths since they render the same rules.
"""
from __future__ import annotations

import shutil
import subprocess

import pytest
import yaml

from clusterdrill import cli
from clusterdrill.cli import HELM_CHART_DIR

REPRESENTATIVE_VALUES = [
    "--set", "image.repository=docker.io/w00dson/clusterdrill",
    "--set", "image.digest=sha256:" + "a" * 64,
    "--set", "auth.existingSecretName=clusterdrill-web-auth",
]

pytestmark = pytest.mark.skipif(
    shutil.which("helm") is None,
    reason="helm is not installed - install it to run these chart tests (see helm/clusterdrill-chart/README.md)",
)


def _helm_template(extra_args: list[str] | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["helm", "template", "clusterdrill", str(HELM_CHART_DIR), "--namespace", "clusterdrill-system",
         *REPRESENTATIVE_VALUES, *(extra_args or [])],
        capture_output=True, text=True,
    )


def _chart_documents() -> list[dict]:
    result = _helm_template()
    assert result.returncode == 0, f"helm template failed: {result.stderr}"
    return [doc for doc in yaml.safe_load_all(result.stdout) if doc]


def _by_kind(docs: list[dict], kind: str) -> list[dict]:
    return [d for d in docs if d.get("kind") == kind]


def _raw_manifest_documents() -> list[dict]:
    rendered = cli.render_manifest(image="clusterdrill:dev", password="unused-for-this-test", version="0.1.0")
    return [doc for doc in yaml.safe_load_all(rendered) if doc]


def test_helm_lint_passes():
    result = subprocess.run(
        ["helm", "lint", str(HELM_CHART_DIR), *REPRESENTATIVE_VALUES],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, f"helm lint failed:\n{result.stdout}\n{result.stderr}"


def test_template_rejects_a_mutable_image_tag():
    """values.schema.json's digest pattern must reject anything that
    isn't `sha256:<64 hex chars>` - a plain tag (including `latest`)
    must never render, matching clusterdrill local install's own
    refusal of non-digest images (cli.py's local_install())."""
    result = _helm_template(extra_args=["--set", "image.digest=latest"])
    assert result.returncode != 0, "chart rendered with a mutable 'latest' digest value - should have been rejected"


def test_default_install_has_no_password_gate():
    """auth.existingSecretName is optional and empty by default (R01-R04's
    'no password gate by default' posture, matching cli.py's
    _resolve_install_password) - a bare install must render successfully
    and must not wire CLUSTERDRILL_PASSWORD at all, the same as the env
    var simply being absent (web/auth.py's password_gate_enabled())."""
    result = subprocess.run(
        ["helm", "template", "clusterdrill", str(HELM_CHART_DIR), "--namespace", "clusterdrill-system",
         "--set", "image.repository=docker.io/w00dson/clusterdrill",
         "--set", "image.digest=sha256:" + "a" * 64],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, f"chart should render without auth.existingSecretName: {result.stderr}"
    docs = [doc for doc in yaml.safe_load_all(result.stdout) if doc]
    deployment = _by_kind(docs, "Deployment")[0]
    env_names = {e["name"] for e in deployment["spec"]["template"]["spec"]["containers"][0]["env"]}
    assert "CLUSTERDRILL_PASSWORD" not in env_names


def test_existing_secret_name_still_wires_the_password_env_var():
    docs = _chart_documents()
    deployment = _by_kind(docs, "Deployment")[0]
    env = {e["name"]: e for e in deployment["spec"]["template"]["spec"]["containers"][0]["env"]}
    assert env["CLUSTERDRILL_PASSWORD"]["valueFrom"]["secretKeyRef"] == {
        "name": "clusterdrill-web-auth", "key": "password",
    }


def test_no_clusterrolebinding_targets_cluster_admin():
    docs = _chart_documents()
    bindings = _by_kind(docs, "ClusterRoleBinding")
    assert bindings
    for binding in bindings:
        assert binding["roleRef"]["name"] != "cluster-admin"


def test_no_clusterrole_grants_a_wildcard_api_group_or_verb():
    docs = _chart_documents()
    roles = _by_kind(docs, "ClusterRole")
    assert roles
    for role in roles:
        for rule in role.get("rules", []):
            assert "*" not in rule.get("apiGroups", [])
            assert "*" not in rule.get("verbs", [])


def test_exactly_one_service_no_ttyd_exposure():
    docs = _chart_documents()
    services = _by_kind(docs, "Service")
    assert len(services) == 1, f"expected exactly one Service, found: {[s['metadata']['name'] for s in services]}"
    service = services[0]
    assert service["metadata"]["name"] == "clusterdrill"
    ports = service["spec"].get("ports", [])
    assert len(ports) == 1
    assert ports[0]["port"] == 8000


def test_no_ingress_or_loadbalancer():
    docs = _chart_documents()
    assert not _by_kind(docs, "Ingress"), "chart must never render an Ingress (see README's Scope section)"
    for service in _by_kind(docs, "Service"):
        assert service["spec"].get("type") != "LoadBalancer"


def test_deployment_security_context_matches_the_raw_manifest():
    chart_deployment = _by_kind(_chart_documents(), "Deployment")[0]
    raw_deployment = _by_kind(_raw_manifest_documents(), "Deployment")[0]
    chart_pod_spec = chart_deployment["spec"]["template"]["spec"]
    raw_pod_spec = raw_deployment["spec"]["template"]["spec"]
    assert chart_pod_spec["securityContext"] == raw_pod_spec["securityContext"]
    # Recreate, not RollingUpdate (R10) - must match the raw manifest so
    # the startup-sweep-vs-overlapping-pod race is closed on both install
    # paths, not just one.
    assert chart_deployment["spec"]["strategy"] == raw_deployment["spec"]["strategy"] == {"type": "Recreate"}
    chart_container = chart_pod_spec["containers"][0]
    raw_container = raw_pod_spec["containers"][0]
    assert chart_container["securityContext"] == raw_container["securityContext"]
    assert chart_container["readinessProbe"] == raw_container["readinessProbe"]
    assert chart_container["livenessProbe"] == raw_container["livenessProbe"]
    # readinessProbe must target /readyz (R10's sweep-completion gate),
    # livenessProbe must stay on /healthz (always-instant, no crash-loop
    # risk) - a regression here would silently reopen R10 on either path.
    assert chart_container["readinessProbe"]["httpGet"]["path"] == "/readyz"
    assert chart_container["livenessProbe"]["httpGet"]["path"] == "/healthz"
    assert chart_container["resources"] == raw_container["resources"]


def test_clusterrole_rules_are_identical_to_the_raw_manifest():
    """The whole point of this chart: the RBAC contract must be
    byte-for-byte the same rules as the already-derived, already-tested
    raw manifest - never a superset, never a subset, never re-derived
    independently and therefore liable to drift."""
    chart_role = _by_kind(_chart_documents(), "ClusterRole")[0]
    raw_role = _by_kind(_raw_manifest_documents(), "ClusterRole")[0]
    assert chart_role["rules"] == raw_role["rules"]


def test_clusterrolebinding_matches_the_raw_manifest():
    chart_binding = _by_kind(_chart_documents(), "ClusterRoleBinding")[0]
    raw_binding = _by_kind(_raw_manifest_documents(), "ClusterRoleBinding")[0]
    assert chart_binding["roleRef"] == raw_binding["roleRef"]
    assert chart_binding["subjects"] == raw_binding["subjects"]


def test_same_resource_kinds_and_names_except_secret_and_namespace():
    """The chart deliberately does not render a Secret (it only
    references one that must already exist, via auth.existingSecretName)
    or a Namespace - both created via kubectl before Helm ever runs (see
    cli.py's local_install_helm). The Namespace omission specifically is
    not a style choice: Helm refuses to "adopt" a pre-existing resource
    into a release unless it already carries Helm's own tracking
    annotations, which a plain `kubectl create namespace` never adds -
    found via a real live install, not guessed. These two are the only
    intentional differences; every other (kind, name) pair must match
    exactly."""
    chart_docs = _chart_documents()
    raw_docs = _raw_manifest_documents()
    chart_pairs = {(d["kind"], d["metadata"]["name"]) for d in chart_docs}
    raw_pairs = {(d["kind"], d["metadata"]["name"]) for d in raw_docs}
    assert raw_pairs - chart_pairs == {
        ("Secret", "clusterdrill-web-auth"),
        ("Namespace", "clusterdrill-system"),
    }
    assert chart_pairs - raw_pairs == set()


def test_deployment_and_service_selectors_match_the_raw_manifest():
    chart_docs = _chart_documents()
    chart_deployment = _by_kind(chart_docs, "Deployment")[0]
    chart_service = _by_kind(chart_docs, "Service")[0]
    assert chart_deployment["spec"]["selector"]["matchLabels"] == {
        "app.kubernetes.io/name": "clusterdrill",
        "app.kubernetes.io/instance": "clusterdrill",
    }
    assert chart_service["spec"]["selector"] == chart_deployment["spec"]["selector"]["matchLabels"]
