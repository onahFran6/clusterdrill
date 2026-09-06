"""Static checks on clusterdrill/manifests/local-appliance.yaml's
RBAC/exposure shape and Kubernetes metadata conventions - no cluster
needed, this is pure YAML parsing (matches test_manifest.py's neighbors in
this directory: no subprocess involved).

The first three tests below cover the essentials explicitly:
reject a ClusterRoleBinding to cluster-admin, reject a wildcard API group,
and reject an exposed ttyd Service. They guard the shape of the manifest
going forward - they do not replace the still-outstanding human security
review of the RBAC contract itself.

The metadata tests below check the metadata convention documented in
docs/adr/0002-kubernetes-metadata-conventions.md. There is no Helm chart
yet, so "raw manifests and the chart emit equivalent metadata" can't be
checked here; these tests instead pin down the raw-manifest side of that
contract so the future chart has a fixed target to match.
"""
from __future__ import annotations

import yaml

from clusterdrill import cli

RECOMMENDED_LABELS = {
    "app.kubernetes.io/name": "clusterdrill",
    "app.kubernetes.io/instance": "clusterdrill",
    "app.kubernetes.io/part-of": "clusterdrill",
    "app.kubernetes.io/managed-by": "clusterdrill-cli",
}
# Present on every resource with a fixed value; app.kubernetes.io/version and
# app.kubernetes.io/component also required, but their value varies (version
# is render-time, component varies per resource) so they're checked separately.


def _load_manifest_documents(version: str = "1.2.3") -> list[dict]:
    rendered = cli.render_manifest(image="clusterdrill:dev", password="unused-for-this-test", version=version)
    return [doc for doc in yaml.safe_load_all(rendered) if doc]


def _cluster_role_bindings(docs: list[dict]) -> list[dict]:
    return [d for d in docs if d.get("kind") == "ClusterRoleBinding"]


def _cluster_roles(docs: list[dict]) -> list[dict]:
    return [d for d in docs if d.get("kind") == "ClusterRole"]


def _services(docs: list[dict]) -> list[dict]:
    return [d for d in docs if d.get("kind") == "Service"]


def _deployments(docs: list[dict]) -> list[dict]:
    return [d for d in docs if d.get("kind") == "Deployment"]


def test_no_clusterrolebinding_targets_cluster_admin():
    docs = _load_manifest_documents()
    bindings = _cluster_role_bindings(docs)
    assert bindings, "expected at least one ClusterRoleBinding in the manifest"
    for binding in bindings:
        role_ref = binding.get("roleRef", {})
        assert role_ref.get("name") != "cluster-admin", (
            f"{binding['metadata']['name']} binds to cluster-admin - the appliance must never "
            "run with cluster-admin, see clusterdrill/manifests/local-appliance.yaml's own comment"
        )


def test_no_clusterrole_grants_a_wildcard_api_group():
    docs = _load_manifest_documents()
    roles = _cluster_roles(docs)
    assert roles, "expected at least one ClusterRole in the manifest"
    for role in roles:
        for rule in role.get("rules", []):
            api_groups = rule.get("apiGroups", [])
            assert "*" not in api_groups, (
                f"{role['metadata']['name']} grants a wildcard apiGroup in rule {rule!r} - "
                "every apiGroup must be named explicitly"
            )


def test_no_clusterrole_grants_a_wildcard_verb():
    """Not one of the first three literal named checks above, but the whole
    point of the "replace broad verb wildcards" scope - a bare
    "*" verb would silently undo the derivation this file documents."""
    docs = _load_manifest_documents()
    roles = _cluster_roles(docs)
    for role in roles:
        for rule in role.get("rules", []):
            verbs = rule.get("verbs", [])
            assert "*" not in verbs, (
                f"{role['metadata']['name']} grants a wildcard verb in rule {rule!r} - "
                "every verb must be named explicitly"
            )


def test_no_service_exposes_ttyd_directly():
    """Invariant: the embedded terminal must never be
    directly reachable, only proxied through the app's own password-gated
    routes (routers/terminal_router.py). The manifest must define exactly
    one Service (the web app's own on port 8000), never a second one for
    ttyd, and that Service must never itself expose a ttyd-facing port."""
    docs = _load_manifest_documents()
    services = _services(docs)
    assert len(services) == 1, (
        f"expected exactly one Service, found: {[s['metadata']['name'] for s in services]}"
    )
    service = services[0]
    assert service["metadata"]["name"] == "clusterdrill"
    assert service["spec"]["type"] == "ClusterIP"
    ports = service.get("spec", {}).get("ports", [])
    assert len(ports) == 1
    assert ports[0]["port"] == 8000


# --- Kubernetes metadata conventions -----------------------------------------

def test_every_resource_carries_the_recommended_labels():
    """Every object in the manifest gets the full app.kubernetes.io/* set
    (docs/adr/0002-kubernetes-metadata-conventions.md) - the fixed-value
    ones with their exact expected value, plus version (render-time) and
    component (varies per resource, but must be present and non-empty)."""
    docs = _load_manifest_documents(version="1.2.3")
    for doc in docs:
        labels = doc.get("metadata", {}).get("labels", {})
        name = f"{doc['kind']}/{doc['metadata']['name']}"
        for key, expected in RECOMMENDED_LABELS.items():
            assert labels.get(key) == expected, f"{name} is missing or has the wrong {key} label"
        assert labels.get("app.kubernetes.io/version") == "1.2.3", f"{name}'s version label wasn't rendered"
        assert labels.get("app.kubernetes.io/component"), f"{name} is missing app.kubernetes.io/component"


def test_deployment_pod_template_carries_the_recommended_labels_too():
    """The recommended labels belong on the Pod template's own metadata as
    well as the Deployment's - kubectl/dashboards read labels off the live
    Pod, not just the Deployment that created it."""
    docs = _load_manifest_documents(version="1.2.3")
    for deployment in _deployments(docs):
        template_labels = deployment["spec"]["template"]["metadata"]["labels"]
        for key, expected in RECOMMENDED_LABELS.items():
            assert template_labels.get(key) == expected
        assert template_labels.get("app.kubernetes.io/version") == "1.2.3"


def test_deployment_selector_only_pins_name_and_instance():
    """spec.selector is immutable after a Deployment is created - a label
    that legitimately changes release to release (version) must never be
    in it, or every upgrade would need a delete-and-recreate instead of a
    rolling update. name+instance never change for this single-instance
    appliance, so they're the only two pinned."""
    docs = _load_manifest_documents()
    for deployment in _deployments(docs):
        match_labels = deployment["spec"]["selector"]["matchLabels"]
        assert match_labels == {
            "app.kubernetes.io/name": "clusterdrill",
            "app.kubernetes.io/instance": "clusterdrill",
        }
        # The selector must select the Pods this same Deployment creates.
        template_labels = deployment["spec"]["template"]["metadata"]["labels"]
        assert match_labels.items() <= template_labels.items()


def test_service_selector_matches_the_deployment_pods():
    """The Service must actually route to the Pods the Deployment creates -
    same immutability reasoning as the Deployment's own selector above."""
    docs = _load_manifest_documents()
    service = _services(docs)[0]
    deployment = _deployments(docs)[0]
    service_selector = service["spec"]["selector"]
    template_labels = deployment["spec"]["template"]["metadata"]["labels"]
    assert service_selector.items() <= template_labels.items()
    assert service_selector == {
        "app.kubernetes.io/name": "clusterdrill",
        "app.kubernetes.io/instance": "clusterdrill",
    }


def test_local_appliance_is_explicitly_single_user():
    docs = _load_manifest_documents()
    deployments = [doc for doc in docs if doc.get("kind") == "Deployment"]
    assert len(deployments) == 1
    env = deployments[0]["spec"]["template"]["spec"]["containers"][0].get("env", [])
    assert {entry["name"]: entry.get("value") for entry in env}["CLUSTERDRILL_SINGLE_USER"] == "true"
