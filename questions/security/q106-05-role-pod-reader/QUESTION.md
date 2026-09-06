# q106-05: Create a Role that grants read-only pod access

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-05-role-pod-reader`

A monitoring sidecar needs to list and inspect pods in its own namespace, and nothing else.

In namespace `q106-05-role-pod-reader`, create a Role named `pod-reader` that grants the `get`,
`list`, and `watch` verbs on the `pods` resource (core API group) only.

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page shows the exact
YAML shape for a namespaced `Role` with `rules`, `apiGroups`, `resources`, and `verbs`.
