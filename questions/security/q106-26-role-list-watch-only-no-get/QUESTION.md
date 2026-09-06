# q106-26-role-list-watch-only-no-get: Create a Role granting only list and watch on pods, not get

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-26-role-list-watch-only-no-get`

`setup.sh` already created, in namespace `q106-26-role-list-watch-only-no-get`, a ServiceAccount
named `dashboard-sa`. No Role or RoleBinding exists yet.

A dashboard component only needs to stream pod status changes - it must never be able to fetch a
single pod's full spec directly.

Create a Role named `pod-watcher` that grants **exactly** the verbs `list` and `watch` on resource
`pods` (core API group) - do **not** grant `get`. Then create a RoleBinding named
`dashboard-binding` in the same namespace that binds the `pod-watcher` Role to the `dashboard-sa`
ServiceAccount.

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page shows the exact
YAML shape for a namespaced `Role` with `rules`, `apiGroups`, `resources`, and `verbs`, plus how a
`RoleBinding` attaches it to a `ServiceAccount` subject.
