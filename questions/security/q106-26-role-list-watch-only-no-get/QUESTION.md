# q106-26-role-list-watch-only-no-get: Create a Role granting only list and watch on pods, not get

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-26-role-list-watch-only-no-get`

Namespace `q106-26-role-list-watch-only-no-get` already has a ServiceAccount named
`dashboard-sa`. No Role or RoleBinding exists yet.

The dashboard only needs to stream pod status changes. It must not be able to fetch a single
pod's full spec.

Create a Role named `pod-watcher` that grants exactly the verbs `list` and `watch` on resource
`pods` (core API group). Do not grant `get`. Then create a RoleBinding named `dashboard-binding`
in the same namespace that binds the `pod-watcher` Role to the `dashboard-sa` ServiceAccount.

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page shows the exact
YAML shape for a namespaced `Role` with `rules`, `apiGroups`, `resources`, and `verbs`, plus how a
`RoleBinding` attaches it to a `ServiceAccount` subject. `get` reads one object; `list` and
`watch` do not include `get` unless you add that verb.
