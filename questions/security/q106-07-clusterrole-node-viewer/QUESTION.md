# q106-07: Create a ClusterRole for a cluster-scoped resource

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-07-clusterrole-node-viewer`

Create a ClusterRole named `q106-07-node-viewer` that grants the `get`, `list`, and `watch` verbs
on the `nodes` resource (core API group).

`ClusterRole` is not namespaced. Label it
`clusterdrill-question: q106-07-clusterrole-node-viewer` so cleanup can find it.

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page explains when a
`ClusterRole` is required instead of a `Role`, and shows the identical `rules` shape. `Node`
objects are cluster-scoped, so a namespaced `Role` cannot grant access to them.
