# q106-07: Create a ClusterRole for a cluster-scoped resource

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-07-clusterrole-node-viewer`

`Node` objects are cluster-scoped, so a namespaced `Role` can never grant access to them - only a
`ClusterRole` can.

Create a ClusterRole named `q106-07-node-viewer` that grants the `get`, `list`, and `watch` verbs
on the `nodes` resource (core API group).

**Important:** `ClusterRole` is not namespaced, but this question still tracks it for cleanup -
make sure it carries the label `clusterdrill-question: q106-07-clusterrole-node-viewer` so it
doesn't leak into later runs.

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page explains when a
`ClusterRole` is required instead of a `Role`, and shows the identical `rules` shape.
