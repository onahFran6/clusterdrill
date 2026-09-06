#!/usr/bin/env python3
"""Resource-kind -> Mermaid diagram-fragment generator.

Reads a question's `resource_kinds` list from its topic's
`domains.fragment.yaml` and emits a Mermaid
`flowchart` fragment whose edges are annotated with the actual kubectl
command or manifest field that creates that relationship - diagrams carry
the command, not just the object graph, so each edge reads as
"do *this* -> get *that* -> which connects to *this*". This is the generator referenced by
`practice-bank/questions/README.md`'s `diagram.mmd` row - its output
replaces the placeholder comment in `questions/_template/diagram.mmd` for
every real question.

Design
------
A lookup table (`_PAIR_EDGES`) maps *ordered pairs* of Kinds to an edge
description: a short relationship phrase plus the concrete kubectl command
or manifest field that creates it (e.g. (Service, Pod) -> "routes to" /
"kubectl expose ... (spec.selector)"). A question's `resource_kinds` list
is treated as a small graph: every pair of kinds in the list is checked
against the table (in both directions), and a matching edge is emitted for
each relationship that applies. Command text is attached directly to the
edge label (rendered on two lines) rather than as separate satellite
nodes, matching how Mermaid flowcharts conventionally annotate edges.

When three or more kinds form a known chain (e.g. ClusterRole ->
ClusterRoleBinding -> ServiceAccount), a direct "shortcut" edge between the
chain's endpoints (ClusterRole -> ServiceAccount) is suppressed in favor of
the more specific multi-hop path, per `_SUPPRESS_IF_CHAIN_PRESENT` - this
keeps the diagram reading as one coherent path instead of a redundant
tangle of overlapping edges.

A kind with no relationship to any other kind in the list (including every
kind in a single-resource question) is expanded into its own canonical
2-3 node chain via `_SOLO_CHAIN` (e.g. `Pod` alone becomes
Pod -> Container -> Image). Any kind not special-cased at all falls back to
a generic "Kind -> generic related node" edge (`_GENERIC_FALLBACK_CHILD`)
rather than crashing or emitting nothing.

Nodes are deduplicated across edges so a Kind mentioned in multiple pairs
(e.g. `Pod` appearing in both a Service-edge and a ConfigMap-edge) appears
once in the diagram with multiple inbound/outbound edges, e.g.
`Ingress -> Service -> Endpoints -> Pod -> ...`.

CLI
---
    lib/generate_diagram.py <question-dir>              # print Mermaid to stdout
    lib/generate_diagram.py <question-dir> --write       # write question-dir/diagram.mmd
    lib/generate_diagram.py --topic <topic-dir> --write  # regenerate every question in a topic
    lib/generate_diagram.py --all --write                # regenerate every question in the bank

<question-dir> is a path like questions/security/q106-02-pod-uses-serviceaccount.
The tool looks up that question's `id` in `<topic>/domains.fragment.yaml`
(the topic dir is the question dir's parent) to find its `resource_kinds`.
Default behavior prints to stdout so a caller can diff/review before
overwriting; pass `--write` to actually replace `<question-dir>/diagram.mmd`.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import sys
from typing import Dict, List, Optional, Tuple

try:
    import yaml
except ImportError:  # pragma: no cover
    print("generate_diagram.py: PyYAML is required (pip install pyyaml)", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Lookup table: ordered-pair edges between Kinds.
#
# Key: (from_kind, to_kind). Value: (edge_label, command)
#   edge_label - short relationship phrase shown on the first line of the arrow
#   command    - the kubectl command or manifest field that creates this edge,
#                shown on the arrow's second line
#
# Only one direction needs to be declared per pair; `_lookup_pair` checks
# both (a, b) and (b, a) so the resource_kinds list order doesn't matter.
# ---------------------------------------------------------------------------

EdgeInfo = Tuple[str, str]

_PAIR_EDGES: Dict[Tuple[str, str], EdgeInfo] = {
    # --- Services & Networking ---------------------------------------------
    ("Ingress", "Service"): (
        "routes to",
        'kubectl create ingress --rule="host/path=svc:port"',
    ),
    ("Service", "Pod"): (
        "routes to",
        "kubectl expose ... (spec.selector)",
    ),
    ("Service", "Endpoints"): (
        "backed by",
        "auto-created from spec.selector match",
    ),
    ("Endpoints", "Pod"): (
        "targets",
        "one subset entry per matching Pod IP:port",
    ),
    ("NetworkPolicy", "Pod"): (
        "selects",
        "kubectl apply -f networkpolicy.yaml (spec.podSelector)",
    ),
    ("NetworkPolicy", "Deployment"): (
        "selects pods of",
        "kubectl apply -f networkpolicy.yaml (spec.podSelector)",
    ),
    # --- Workloads: Deployment/ReplicaSet/Pod -------------------------------
    ("Deployment", "ReplicaSet"): (
        "owns",
        "kubectl create deployment ... (controller creates on template change)",
    ),
    ("ReplicaSet", "Pod"): (
        "owns",
        "created to match spec.replicas",
    ),
    ("Deployment", "Pod"): (
        "manages via ReplicaSet",
        "kubectl create deployment ...",
    ),
    ("Deployment", "Service"): (
        "exposed by",
        "kubectl expose deployment ... (selector matches pod-template labels)",
    ),
    ("Deployment", "ConfigMap"): (
        "reads",
        "envFrom / volumeMount; kubectl rollout restart on change",
    ),
    ("Deployment", "PersistentVolumeClaim"): (
        "mounts",
        "pod template spec.volumes.persistentVolumeClaim.claimName",
    ),
    ("HorizontalPodAutoscaler", "Deployment"): (
        "scales",
        "kubectl autoscale deployment ... --min --max --cpu-percent (spec.scaleTargetRef)",
    ),
    # --- Jobs / CronJobs -----------------------------------------------------
    ("CronJob", "Job"): (
        "schedules",
        "kubectl create cronjob ... --schedule=... (fires on each tick)",
    ),
    ("Job", "Pod"): (
        "owns",
        "kubectl create job ... (spec.completions/spec.parallelism)",
    ),
    # --- Configuration ---------------------------------------------------------
    ("ConfigMap", "Pod"): (
        "consumed by",
        "kubectl create configmap ...; envFrom / valueFrom / volumeMount",
    ),
    ("Secret", "Pod"): (
        "consumed by",
        "kubectl create secret ...; envFrom / valueFrom / volumeMount",
    ),
    ("LimitRange", "Pod"): (
        "constrains",
        "kubectl apply -f limitrange.yaml (default/min/max at admission)",
    ),
    ("ResourceQuota", "Pod"): (
        "constrains",
        "kubectl apply -f resourcequota.yaml (namespace aggregate)",
    ),
    # --- Storage -----------------------------------------------------------------
    ("PersistentVolume", "PersistentVolumeClaim"): (
        "bound by",
        "kubectl apply -f pv.yaml + pvc.yaml (capacity/accessMode match)",
    ),
    ("PersistentVolumeClaim", "Pod"): (
        "mounted by",
        "spec.volumes.persistentVolumeClaim.claimName",
    ),
    ("StorageClass", "PersistentVolumeClaim"): (
        "provisions for",
        "spec.storageClassName references it; PV dynamically provisioned",
    ),
    ("StorageClass", "PersistentVolume"): (
        "dynamically provisions",
        "kubectl apply -f storageclass.yaml + pvc.yaml (triggers provisioner)",
    ),
    # --- RBAC / Security -----------------------------------------------------------
    ("ServiceAccount", "Pod"): (
        "identity for",
        "kubectl create serviceaccount ...; spec.serviceAccountName",
    ),
    ("Role", "RoleBinding"): (
        "granted by",
        "kubectl create role ...; kubectl create rolebinding ...",
    ),
    ("RoleBinding", "ServiceAccount"): (
        "binds",
        "roleRef + subjects[].kind: ServiceAccount",
    ),
    ("ClusterRole", "ClusterRoleBinding"): (
        "granted by",
        "kubectl create clusterrole ...; kubectl create clusterrolebinding ...",
    ),
    ("ClusterRoleBinding", "ServiceAccount"): (
        "binds",
        "roleRef + subjects[].kind: ServiceAccount",
    ),
    ("Role", "ServiceAccount"): (
        "authorizes",
        "via an intervening RoleBinding (roleRef + subjects)",
    ),
    ("ClusterRole", "ServiceAccount"): (
        "authorizes",
        "via an intervening ClusterRoleBinding (roleRef + subjects)",
    ),
    ("Secret", "ServiceAccount"): (
        "accessible to",
        "readable only if a bound Role/ClusterRole grants get/list on secrets",
    ),
    ("ConfigMap", "ServiceAccount"): (
        "readable by",
        "subject to RBAC on the ServiceAccount's bound Role",
    ),
    # --- Helm / CRDs -----------------------------------------------------------------
    ("CustomResourceDefinition", "Deployment"): (
        "registers Kind used by",
        "kubectl apply -f crd.yaml; operator Deployment watches CR instances",
    ),
    ("CustomResourceDefinition", "ConfigMap"): (
        "schema queried via",
        "kubectl get <crd-plural> -o jsonpath=...",
    ),
    # --- Scheduling ---------------------------------------------------------------------
    ("Pod", "Node"): (
        "scheduled to",
        "kubectl label node ...; spec.nodeSelector match",
    ),
}

# ---------------------------------------------------------------------------
# Kind -> node type, used only by the JSON/SVG renderer (render_json() below)
# for coloring and the legend - Mermaid output ignores this entirely. Any
# Kind not listed here (e.g. an ad-hoc node from _GENERIC_FALLBACK_CHILD or a
# solo-chain synthetic node like "Container"/"Image") falls back to
# "external" in node_type(), the same bucket the Figma Make prototype this
# was ported from uses for anything outside its own small taxonomy.
# ---------------------------------------------------------------------------
_KIND_TYPE: Dict[str, str] = {
    "Deployment": "controller",
    "ReplicaSet": "controller",
    "Job": "controller",
    "CronJob": "controller",
    "HorizontalPodAutoscaler": "controller",
    "Pod": "pod",
    "Container": "pod",
    "Image": "pod",
    "Service": "service",
    "Ingress": "service",
    "Endpoints": "service",
    "NetworkPolicy": "service",
    "ConfigMap": "resource",
    "Secret": "resource",
    "PersistentVolume": "storage",
    "PersistentVolumeClaim": "storage",
    "StorageClass": "storage",
    "Role": "policy",
    "RoleBinding": "policy",
    "ClusterRole": "policy",
    "ClusterRoleBinding": "policy",
    "ResourceQuota": "policy",
    "LimitRange": "policy",
    "ServiceAccount": "external",
    "Node": "external",
    "Namespace": "external",
    "CustomResourceDefinition": "external",
    "Custom Resource": "external",
}


def node_type(label: str) -> str:
    """Classify a node label into one of the JSON renderer's color buckets.
    Solo-chain/fallback labels can carry extra text (e.g. a QoS class node),
    so an exact match against the Kind lookup comes first, falling back to
    "external" - the same catch-all bucket the source prototype uses for
    anything outside its own small taxonomy."""
    return _KIND_TYPE.get(label, "external")


# ---------------------------------------------------------------------------
# Sequence view rewrite: kubectl never talks to a Job or a Pod directly - it
# only ever talks to the API server, which persists the object, and then a
# *specific* in-cluster component (a controller's watch loop, the scheduler,
# or kubelet) reacts asynchronously. The old sequence_json() just replayed
# the architecture edges verbatim ("kubectl -> Job: creates", "Job -> Pod:
# owns"), which is a fine *object graph* but a misleading *request flow* -
# nothing in that picture is actually a call between "Job" and "Pod" as
# actors; both are passive API objects. This table is what fixes that: it
# classifies every relationship verb already in _PAIR_EDGES/_SOLO_CHAIN by
# *which real control-plane component performs it*, so sequence_json() can
# route each step through the actor that's actually doing the work.
#
#   "reconcile" - a named controller (_CONTROLLER_NAME) watches the edge's
#                 "from" Kind and creates/updates the "to" Kind as a side
#                 effect - Deployment -> ReplicaSet -> Pod, CronJob -> Job,
#                 Service -> Endpoints, HPA -> Deployment, etc. Rendered as
#                 two steps (the controller's watch, then its write) so the
#                 diagram makes the asynchronous "watch loop", not a direct
#                 call, visually obvious.
#   "schedule"  - triggers the Scheduler + kubelet block (see
#                 _emit_schedule_and_run in sequence_json) - only meaningful
#                 when paired with an actual Pod object.
#   "runtime"   - kubelet's job, not the API server's - it reads/mounts/
#                 injects this into a container at pod-start time, well
#                 after the object itself was already created and admitted.
#   "admission" - enforced inline by the API server's admission chain or
#                 authorizer at request time (RBAC, quotas, NetworkPolicy) -
#                 there is no separate watch-loop component for these.
#   (unlisted)  - falls back to "direct": a plain API-server-mediated link
#                 with no interesting extra machinery - still routed through
#                 "API Server" rather than left as a bare Kind-to-Kind
#                 arrow, since nothing in Kubernetes ever skips it.
_SEQ_VERB_KIND: Dict[str, str] = {
    "owns": "reconcile",
    "schedules": "reconcile",
    "backed by": "reconcile",
    "dynamically provisions": "reconcile",
    "bound by": "reconcile",
    "provisions": "reconcile",
    "provisions for": "reconcile",
    "scales": "reconcile",
    "hosts": "schedule",
    "scheduled to": "schedule",
    "consumed by": "runtime",
    "mounted by": "runtime",
    "mounts": "runtime",
    "identity for": "runtime",
    "runs": "runtime",
    "pulls": "runtime",
    "constrains": "admission",
    "binds": "admission",
    "authorizes": "admission",
    "granted by": "admission",
    "selects": "admission",
    "selects pods of": "admission",
    "accessible to": "admission",
    "readable by": "admission",
}

# Which named controller (inside kube-controller-manager, or an external
# provisioner for StorageClass) reconciles a given Kind. Any Kind not listed
# still gets a "reconcile" step if its relationship calls for one - falls
# back to a generated "<Kind> controller" name in sequence_json(), which is
# a defensible default since every built-in Kubernetes "owns" relationship
# genuinely is driven by a specifically-named controller, even ones this
# table hasn't spelled out yet.
_CONTROLLER_NAME: Dict[str, str] = {
    "Deployment": "Deployment controller",
    "ReplicaSet": "ReplicaSet controller",
    "Job": "Job controller",
    "CronJob": "CronJob controller",
    "Service": "Endpoints controller",
    "StorageClass": "PV controller",
    "PersistentVolume": "PV controller",
    "HorizontalPodAutoscaler": "HPA controller",
}

# Synthetic solo-chain nodes that describe what's *inside* a Pod (not a
# separate Kubernetes API object a controller or kubectl can act on) - the
# Scheduler+kubelet block already covers "kubelet pulls image(s), starts
# container(s)" once, so a separate "Pod runs Container" / "Container pulls
# Image" step would just repeat that in less accurate language. Skipped in
# the Sequence view only; render_json()'s Architecture view still shows them
# as ordinary nodes, since visualizing "what's inside the box" is exactly
# what that view is for.
_SEQ_SKIP_TARGETS = {"Container", "Image", "QoS class"}

_API_SERVER = "API Server"
_SCHEDULER = "Scheduler"
_KUBELET = "kubelet"


# When all three kinds of a chain (a, b, c) are present together, suppress
# the direct shortcut edge (a, c) in favor of showing only a -> b -> c, so
# the diagram reads as one coherent path instead of a redundant tangle.
_SUPPRESS_IF_CHAIN_PRESENT: List[Tuple[str, str, str]] = [
    ("ClusterRole", "ClusterRoleBinding", "ServiceAccount"),
    ("Role", "RoleBinding", "ServiceAccount"),
    ("Ingress", "Service", "Pod"),
    ("Deployment", "ReplicaSet", "Pod"),
    ("CronJob", "Job", "Pod"),
    ("Service", "Endpoints", "Pod"),
    ("StorageClass", "PersistentVolume", "PersistentVolumeClaim"),
]

# ---------------------------------------------------------------------------
# Solo chains: canonical little diagram for a Kind that appears with no
# partner it has a declared pair-relationship with (including the
# single-resource-question case, e.g. resource_kinds: [Pod]).
# Each entry is a list of (node, edge_label, command) describing a
# straight-line chain rooted at that Kind; edge_label/command annotate the
# edge *arriving* at that node (None on the first node, which has no
# incoming edge).
# ---------------------------------------------------------------------------

Step = Tuple[str, Optional[str], Optional[str]]

_SOLO_CHAIN: Dict[str, List[Step]] = {
    "Pod": [
        ("Pod", None, "kubectl run web --image=... / kubectl apply -f pod.yaml"),
        ("Container", "runs", None),
        ("Image", "pulls", "imagePullPolicy on kubelet's first run"),
    ],
    "Deployment": [
        ("Deployment", None, "kubectl create deployment ..."),
        ("ReplicaSet", "owns", "controller creates on template change"),
        ("Pod", "owns", "created to match spec.replicas"),
    ],
    "ReplicaSet": [
        ("ReplicaSet", None, "kubectl apply -f replicaset.yaml"),
        ("Pod", "owns", "created to match spec.replicas"),
    ],
    "Service": [
        ("Service", None, "kubectl expose ... / kubectl apply -f service.yaml"),
        ("Pod", "routes to", "via spec.selector label match"),
    ],
    "Endpoints": [
        ("Service", None, "kubectl apply -f service.yaml"),
        ("Endpoints", "backed by", "auto-created from spec.selector match"),
        ("Pod", "targets", None),
    ],
    "Ingress": [
        ("Ingress", None, "kubectl create ingress ..."),
        ("Service", "routes to", None),
        ("Pod", "routes to", "via spec.selector label match"),
    ],
    "NetworkPolicy": [
        ("NetworkPolicy", None, "kubectl apply -f networkpolicy.yaml"),
        ("Pod", "selects", "spec.podSelector label match"),
    ],
    "ConfigMap": [
        ("ConfigMap", None, "kubectl create configmap ..."),
        ("Container", "consumed by", "via envFrom / volumeMount"),
    ],
    "Secret": [
        ("Secret", None, "kubectl create secret ..."),
        ("Container", "consumed by", "via envFrom / volumeMount"),
    ],
    "LimitRange": [
        ("LimitRange", None, "kubectl apply -f limitrange.yaml"),
        ("Pod", "constrains", "default/min/max applied at admission"),
    ],
    "ResourceQuota": [
        ("ResourceQuota", None, "kubectl apply -f resourcequota.yaml"),
        ("Namespace", "constrains", "aggregate usage capped per namespace"),
    ],
    "PersistentVolume": [
        ("PersistentVolume", None, "kubectl apply -f pv.yaml"),
        ("PersistentVolumeClaim", "bound by", "capacity/accessMode match"),
    ],
    "PersistentVolumeClaim": [
        ("PersistentVolumeClaim", None, "kubectl apply -f pvc.yaml"),
        ("Pod", "mounted by", "spec.volumes.persistentVolumeClaim.claimName"),
    ],
    "StorageClass": [
        ("StorageClass", None, "kubectl apply -f storageclass.yaml"),
        ("PersistentVolume", "provisions", "dynamically provisioned on PVC create"),
        ("PersistentVolumeClaim", "bound by", None),
    ],
    "ServiceAccount": [
        ("ServiceAccount", None, "kubectl create serviceaccount ..."),
        ("Pod", "identity for", "spec.serviceAccountName"),
    ],
    "Role": [
        ("Role", None, "kubectl create role ..."),
        ("RoleBinding", "granted by", "kubectl create rolebinding ..."),
        ("ServiceAccount", "binds", None),
    ],
    "RoleBinding": [
        ("RoleBinding", None, "kubectl create rolebinding ..."),
        ("ServiceAccount", "binds", "subjects[].kind: ServiceAccount"),
    ],
    "ClusterRole": [
        ("ClusterRole", None, "kubectl create clusterrole ..."),
        ("ClusterRoleBinding", "granted by", "kubectl create clusterrolebinding ..."),
        ("ServiceAccount", "binds", None),
    ],
    "ClusterRoleBinding": [
        ("ClusterRoleBinding", None, "kubectl create clusterrolebinding ..."),
        ("ServiceAccount", "binds", "subjects[].kind: ServiceAccount"),
    ],
    "Job": [
        ("Job", None, "kubectl create job ..."),
        ("Pod", "owns", "created to satisfy spec.completions/parallelism"),
    ],
    "CronJob": [
        ("CronJob", None, "kubectl create cronjob ... --schedule=..."),
        ("Job", "schedules", "created on each scheduled tick"),
        ("Pod", "owns", None),
    ],
    "CustomResourceDefinition": [
        ("CustomResourceDefinition", None, "kubectl apply -f crd.yaml"),
        ("Custom Resource", "registers Kind for", "kubectl apply -f cr-instance.yaml"),
    ],
    "Node": [
        ("Node", None, "kubectl label node ..."),
        ("Pod", "hosts", "spec.nodeSelector / nodeAffinity match"),
    ],
}

# Fallback for any Kind with neither a pair entry nor a solo chain.
_GENERIC_FALLBACK_CHILD = "related object"
_GENERIC_FALLBACK_LABEL = "relates to"
_GENERIC_FALLBACK_COMMAND = "no special-cased relationship yet - see resource_kinds"


def _lookup_pair(a: str, b: str) -> Optional[Tuple[str, str, EdgeInfo]]:
    """Return (from_kind, to_kind, edge_info) if a declared edge exists
    between a and b in either direction, else None."""
    if (a, b) in _PAIR_EDGES:
        return a, b, _PAIR_EDGES[(a, b)]
    if (b, a) in _PAIR_EDGES:
        return b, a, _PAIR_EDGES[(b, a)]
    return None


def _sanitize_id(text: str) -> str:
    """Turn a free-form node label into a Mermaid-safe node id."""
    safe = "".join(ch if ch.isalnum() else "_" for ch in text)
    if not safe or not (safe[0].isalpha() or safe[0] == "_"):
        safe = f"n_{safe}"
    return safe


def _mermaid_label(text: str) -> str:
    """Escape a string for use inside a Mermaid quoted node/edge label."""
    return text.replace('"', "'")


class DiagramBuilder:
    """Accumulates nodes/edges while de-duplicating by node id."""

    def __init__(self) -> None:
        self._node_labels: Dict[str, str] = {}
        self._edges: List[Tuple[str, str, Optional[str], Optional[str]]] = []
        self._edge_seen = set()
        # A solo chain's first entry (e.g. Job's own "kubectl create job ...")
        # has no incoming edge to attach that command to - render()/
        # render_json() never needed it (Architecture only draws edges), but
        # sequence_json()'s opening "how was this node itself created" step
        # does. Keyed by node id, populated only where a real creation
        # command is known; sequence_json() falls back to an edge's own
        # command (imperfect but reasonable for pair-edge chains) or a
        # generic "creates X" when neither is available.
        self._node_creation_command: Dict[str, str] = {}

    def node(self, label: str) -> str:
        node_id = _sanitize_id(label)
        self._node_labels.setdefault(node_id, label)
        return node_id

    def set_creation_command(self, label: str, command: Optional[str]) -> None:
        if command:
            self._node_creation_command[self.node(label)] = command

    def edge(
        self,
        from_label: str,
        to_label: str,
        relationship: Optional[str] = None,
        command: Optional[str] = None,
    ) -> None:
        from_id = self.node(from_label)
        to_id = self.node(to_label)
        key = (from_id, to_id)
        if key in self._edge_seen:
            return
        self._edge_seen.add(key)
        self._edges.append((from_id, to_id, relationship, command))

    def render(self, title: str) -> str:
        lines = ["flowchart LR"]
        for node_id, label in self._node_labels.items():
            lines.append(f'    {node_id}["{_mermaid_label(label)}"]')
        for from_id, to_id, relationship, command in self._edges:
            if relationship and command:
                label = f"{relationship}<br/><small>{_mermaid_label(command)}</small>"
                lines.append(f'    {from_id} -->|"{label}"| {to_id}')
            elif relationship:
                lines.append(f'    {from_id} -->|"{_mermaid_label(relationship)}"| {to_id}')
            elif command:
                lines.append(f'    {from_id} -.->|"{_mermaid_label(command)}"| {to_id}')
            else:
                lines.append(f"    {from_id} --> {to_id}")
        header = [
            f"%% {title}",
            "%% Generated by practice-bank/lib/generate_diagram.py from this",
            "%% question's resource_kinds in domains.fragment.yaml. Do not hand-edit -",
            "%% re-run the generator instead (see the script's --help for usage).",
        ]
        return "\n".join(header) + "\n" + "\n".join(lines) + "\n"

    def render_json(self, title: str, description: str) -> dict:
        """JSON sibling of render(), for the Diagram tab's Architecture view
        (static/diagram.js) - same node/edge data, no Mermaid syntax. Every
        edge is marked "animated" (the flow-dot renderer's default-on
        treatment, ported as-is from the source Figma Make prototype - see
        the Diagram tab rebuild plan) since a generated diagram has no
        curated "this is the one relationship that matters" edge to single
        out the way a hand-authored one might."""
        nodes = [
            {"id": node_id, "label": label, "type": node_type(label)}
            for node_id, label in self._node_labels.items()
        ]
        edges = []
        for from_id, to_id, relationship, command in self._edges:
            edge = {"from": from_id, "to": to_id, "label": relationship or command, "animated": True}
            if command:
                edge["command"] = command
            edges.append(edge)
        return {"title": title, "description": description, "nodes": nodes, "edges": edges}

    def sequence_json(self, title: str, description: str) -> dict:
        """Derive a Sequence view from the same edge list render_json() uses -
        no separate authoring, per the Diagram tab rebuild plan's "generated,
        not hand-authored" decision. Unlike the architecture edges (a fair
        object graph on its own), a *sequence* diagram that just replays
        "kubectl -> Job: creates, Job -> Pod: owns" verbatim is misleading -
        kubectl never talks to a Job or a Pod, only ever to the API server.
        This version routes every step through the control-plane component
        that actually performs it (_SEQ_VERB_KIND/_CONTROLLER_NAME above):
        kubectl always opens with a real request/response round trip to the
        API server; a controller's *watch loop* (not a direct call) is what
        creates a child object; the Scheduler and kubelet get their own
        block the first time a real Pod object appears anywhere in the
        chain; RBAC/quota/NetworkPolicy-style edges are shown as enforced
        inline by the API server rather than as a bare object-to-object
        arrow. Every question still gets one for free from the same
        resource_kinds data - see the Diagram tab rebuild's "generated, not
        hand-authored" call, now extended to the control-plane detail too.
        """
        introduced: set = set()
        actor_ids: set = {"kubectl", _API_SERVER}
        actors: List[dict] = [
            {"id": "kubectl", "label": "kubectl", "type": "external"},
            {"id": _API_SERVER, "label": _API_SERVER, "type": "external"},
        ]
        steps: List[dict] = []
        scheduled = {"done": False}

        def ensure_actor(node_id: str, label: Optional[str] = None, actor_type: Optional[str] = None) -> None:
            if node_id in actor_ids:
                return
            actor_ids.add(node_id)
            resolved_label = label or self._node_labels.get(node_id, node_id)
            actors.append({
                "id": node_id,
                "label": resolved_label,
                "type": actor_type or node_type(resolved_label),
            })

        # Runtime-consumption facts (ConfigMap injected, Secret mounted,
        # ServiceAccount identity, ...) all really happen at the same
        # moment - when kubelet starts the Pod's containers - regardless of
        # which order their edges happen to appear in the resource_kinds
        # list. Collected here and folded into the one kubelet step
        # emit_schedule_and_run() emits, instead of scattering them as
        # separate steps that could otherwise land *before* the Pod has
        # even been scheduled - a real ordering bug the first version of
        # this rewrite had (kubelet "consuming" a ConfigMap before the
        # Scheduler had bound the Pod to a Node at all).
        runtime_notes: List[str] = []

        def emit_schedule_and_run() -> None:
            if scheduled["done"] or "Pod" not in self._node_labels:
                return
            scheduled["done"] = True
            ensure_actor(_SCHEDULER, _SCHEDULER, "controller")
            ensure_actor(_KUBELET, _KUBELET, "external")
            steps.append({"from": _SCHEDULER, "to": _API_SERVER, "label": "watches for unscheduled Pods"})
            steps.append({"from": _SCHEDULER, "to": _API_SERVER, "label": "binds the Pod to a Node"})
            steps.append({"from": _KUBELET, "to": _API_SERVER, "label": "watches Pods bound to its Node"})
            run_label = "pulls image(s), starts container(s)"
            if runtime_notes:
                run_label += " - " + ", ".join(runtime_notes)
            steps.append({"from": _KUBELET, "to": "Pod", "label": run_label})
            steps.append({"from": _KUBELET, "to": _API_SERVER, "label": "reports Running status", "dashed": True})

        def open_request(node_id: str, label: str, edge_command: Optional[str], fallback: str) -> None:
            if node_id in introduced:
                return
            introduced.add(node_id)
            # Prefer this node's own recorded creation command (solo
            # chains) over the edge's command, which describes how the
            # *next* node came from this one, not how this one itself was
            # created - see set_creation_command()'s docstring. A pair
            # edge's command is only trustworthy here if it actually reads
            # as an imperative creation command - some (e.g. "pod template
            # spec.volumes.persistentVolumeClaim.claimName") are manifest
            # field references instead, which would misrepresent "how was
            # this node created" if used as-is.
            command = self._node_creation_command.get(node_id) or edge_command
            if command and not any(kw in command for kw in ("kubectl create", "kubectl apply", "kubectl run", "kubectl expose", "kubectl label", "kubectl autoscale")):
                command = None
            steps.append({"from": "kubectl", "to": _API_SERVER, "label": command or fallback})
            steps.append({"from": _API_SERVER, "to": "kubectl", "label": "201 Created", "dashed": True})

        if not self._edges:
            # A single unconnected node (e.g. a lone ResourceQuota with no
            # other resource_kinds to relate it to) still gets the basic
            # kubectl<->API server round trip rather than an empty diagram.
            for node_id, label in self._node_labels.items():
                ensure_actor(node_id, label, node_type(label))
                open_request(node_id, label, None, f"creates {label}")
            emit_schedule_and_run()
            return {"title": title, "description": description, "actors": actors, "steps": steps}

        for from_id, to_id, relationship, command in self._edges:
            from_label = self._node_labels.get(from_id, from_id)
            to_label = self._node_labels.get(to_id, to_id)
            ensure_actor(from_id, from_label, node_type(from_label))
            open_request(from_id, from_label, command, f"creates {from_label}")

            if to_label in _SEQ_SKIP_TARGETS:
                introduced.add(to_id)
                continue

            ensure_actor(to_id, to_label, node_type(to_label))
            verb_kind = _SEQ_VERB_KIND.get(relationship, "direct")

            if verb_kind == "reconcile":
                controller = _CONTROLLER_NAME.get(from_label, f"{from_label} controller")
                ensure_actor(controller, controller, "controller")
                steps.append({"from": controller, "to": _API_SERVER, "label": f"watches {from_label} objects"})
                write_label = f"{relationship} {to_label}"
                if command:
                    write_label += f" ({command})"
                steps.append({"from": controller, "to": _API_SERVER, "label": write_label})
            elif verb_kind == "runtime":
                note = f"{relationship} {from_label}"
                if command:
                    note += f" ({command})"
                if to_label == "Pod":
                    # Folded into the kubelet step emit_schedule_and_run()
                    # emits below, since that's genuinely when this happens.
                    runtime_notes.append(note)
                else:
                    # No explicit "Pod" node in this diagram (e.g. a
                    # Deployment+PersistentVolumeClaim pair, where the Pod
                    # template's own mount is implied, not a separate node)
                    # - nothing to fold this into, so it's kubelet's own
                    # immediate step instead of silently dropped.
                    ensure_actor(_KUBELET, _KUBELET, "external")
                    steps.append({"from": _KUBELET, "to": to_id, "label": note})
            elif verb_kind == "admission":
                steps.append({"from": _API_SERVER, "to": to_id, "label": f"{relationship} (enforced at request time)"})
            else:
                steps.append({"from": _API_SERVER, "to": to_id, "label": relationship or command or "relates to"})

            introduced.add(to_id)

        emit_schedule_and_run()
        return {"title": title, "description": description, "actors": actors, "steps": steps}


def _build_graph(resource_kinds: List[str]) -> Tuple[DiagramBuilder, List[str]]:
    """Shared graph-building logic behind both generate_mermaid() and
    generate_diagram_json() - walks a question's resource_kinds once via the
    _PAIR_EDGES/_SUPPRESS_IF_CHAIN_PRESENT/_SOLO_CHAIN tables and returns the
    populated DiagramBuilder plus the de-duped kinds list (needed by callers
    to build a title/description), so the two output formats can never drift
    out of sync with each other."""
    kinds = list(dict.fromkeys(resource_kinds))  # de-dup, preserve order
    builder = DiagramBuilder()

    if not kinds:
        builder.node("(no resource_kinds declared)")
        return builder, kinds

    kind_set = set(kinds)
    matched_kinds = set()

    if len(kinds) >= 2:
        for i, a in enumerate(kinds):
            for b in kinds[i + 1 :]:
                found = _lookup_pair(a, b)
                if found is None:
                    continue
                from_kind, to_kind, edge_info = found
                # Skip edges that are the "shortcut" leg of a known chain
                # (e.g. ClusterRole -> ServiceAccount when ClusterRoleBinding
                # is also present) so the multi-hop path renders instead of
                # a redundant tangle of overlapping edges. The chain's own
                # two hops are always separately present in _PAIR_EDGES and
                # get emitted by their own iteration of this loop.
                is_shortcut = any(
                    {chain_a, chain_c} == {from_kind, to_kind} and chain_b in kind_set
                    for chain_a, chain_b, chain_c in _SUPPRESS_IF_CHAIN_PRESENT
                )
                if is_shortcut:
                    matched_kinds.add(a)
                    matched_kinds.add(b)
                    continue
                relationship, command = edge_info
                builder.edge(from_kind, to_kind, relationship, command)
                matched_kinds.add(a)
                matched_kinds.add(b)

    # Any kind not covered by a pair match above (including every kind in a
    # single-resource question) gets expanded via its solo chain, or the
    # generic fallback if it has no chain declared either.
    for kind in kinds:
        if kind in matched_kinds:
            continue
        chain = _SOLO_CHAIN.get(kind)
        if chain:
            for idx, (node_label, relationship, command) in enumerate(chain):
                if idx == 0:
                    builder.node(node_label)
                    builder.set_creation_command(node_label, command)
                    continue
                prev_label = chain[idx - 1][0]
                builder.edge(prev_label, node_label, relationship, command)
        else:
            builder.node(kind)
            builder.edge(kind, _GENERIC_FALLBACK_CHILD, _GENERIC_FALLBACK_LABEL, _GENERIC_FALLBACK_COMMAND)

    return builder, kinds


def generate_mermaid(resource_kinds: List[str], question_id: str) -> str:
    """Build a Mermaid flowchart fragment for a question's resource_kinds."""
    builder, kinds = _build_graph(resource_kinds)
    if not kinds:
        return builder.render(question_id)
    return builder.render(f"{question_id}: {', '.join(kinds)}")


def generate_diagram_json(resource_kinds: List[str], question_id: str) -> dict:
    """Build the Diagram tab's JSON payload (architecture + sequence) for a
    question's resource_kinds - the JSON sibling of generate_mermaid(),
    sharing the exact same graph via _build_graph() so both output formats
    always describe the same relationships."""
    builder, kinds = _build_graph(resource_kinds)
    if not kinds:
        title, description = question_id, "(no resource_kinds declared)"
    else:
        title = f"{question_id}: {', '.join(kinds)}"
        description = f"Resources involved: {', '.join(kinds)}"
    return {
        "architecture": builder.render_json(title, description),
        "sequence": builder.sequence_json(title, description),
    }


def _load_topic_fragment(topic_dir: str) -> dict:
    fragment_path = os.path.join(topic_dir, "domains.fragment.yaml")
    with open(fragment_path) as f:
        return yaml.safe_load(f) or {}


def _find_question_entry(fragment: dict, question_id: str) -> Optional[dict]:
    for q in fragment.get("questions", []):
        if q.get("id") == question_id:
            return q
    return None


def _resolve_question(question_dir: str) -> Tuple[List[str], str]:
    """Look up a question's resource_kinds + id from its topic's
    domains.fragment.yaml - shared by both the Mermaid and JSON output
    paths in main() so they never resolve against different data."""
    question_dir = os.path.normpath(question_dir)
    question_id = os.path.basename(question_dir)
    topic_dir = os.path.dirname(question_dir)
    fragment = _load_topic_fragment(topic_dir)
    entry = _find_question_entry(fragment, question_id)
    if entry is None:
        raise SystemExit(
            f"generate_diagram.py: question id '{question_id}' not found in "
            f"{os.path.join(topic_dir, 'domains.fragment.yaml')}"
        )
    return entry.get("resource_kinds", []), question_id


def generate_for_question_dir(question_dir: str) -> str:
    resource_kinds, question_id = _resolve_question(question_dir)
    return generate_mermaid(resource_kinds, question_id)


def generate_json_for_question_dir(question_dir: str) -> dict:
    resource_kinds, question_id = _resolve_question(question_dir)
    return generate_diagram_json(resource_kinds, question_id)


def _iter_question_dirs(topic_dir: str):
    for path in sorted(glob.glob(os.path.join(topic_dir, "q*"))):
        if os.path.isdir(path):
            yield path


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Generate a Mermaid diagram.mmd fragment from a question's resource_kinds.",
    )
    parser.add_argument(
        "question_dir",
        nargs="?",
        help="Path to a question folder, e.g. questions/security/q106-02-pod-uses-serviceaccount",
    )
    parser.add_argument(
        "--topic",
        help="Regenerate every question under this topic dir, e.g. questions/security",
    )
    parser.add_argument(
        "--all",
        metavar="QUESTIONS_ROOT",
        nargs="?",
        const="questions",
        help="Regenerate every question in every topic under QUESTIONS_ROOT (default: questions). "
        "Skips _template and any dir without a domains.fragment.yaml (e.g. community).",
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Write output to <question-dir>/diagram.mmd instead of printing to stdout.",
    )
    args = parser.parse_args(argv)

    targets: List[str] = []
    if args.all is not None:
        for topic_dir in sorted(glob.glob(os.path.join(args.all, "*"))):
            if not os.path.isdir(topic_dir):
                continue
            if os.path.basename(topic_dir) in ("_template", "community"):
                continue
            if not os.path.exists(os.path.join(topic_dir, "domains.fragment.yaml")):
                continue
            targets.extend(_iter_question_dirs(topic_dir))
    elif args.topic is not None:
        targets.extend(_iter_question_dirs(args.topic))
    elif args.question_dir is not None:
        targets.append(args.question_dir)
    else:
        parser.error("provide a question_dir, or use --topic / --all")

    for question_dir in targets:
        try:
            mermaid = generate_for_question_dir(question_dir)
            diagram_json = generate_json_for_question_dir(question_dir)
        except SystemExit as e:
            print(str(e), file=sys.stderr)
            continue
        if args.write:
            mmd_path = os.path.join(question_dir, "diagram.mmd")
            with open(mmd_path, "w") as f:
                f.write(mermaid)
            print(f"wrote {mmd_path}", file=sys.stderr)
            json_path = os.path.join(question_dir, "diagram.json")
            with open(json_path, "w") as f:
                json.dump(diagram_json, f, indent=2)
                f.write("\n")
            print(f"wrote {json_path}", file=sys.stderr)
        else:
            print(f"--- {question_dir} ---")
            print(mermaid)
            print(json.dumps(diagram_json, indent=2))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
