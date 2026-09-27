# q106-47: Fix a RoleBinding resolving to the wrong same-named role kind

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-47-rolebinding-roleref-kind-mismatch`

This namespace already has a ServiceAccount named `auditor`, a Role named
`q106-47-secret-reader` (grants `get`/`list` on `secrets`), a ClusterRole with the same name
`q106-47-secret-reader` (grants only `get` on `configmaps` cluster-wide), and a RoleBinding
named `auditor-binding`. `auditor` cannot read Secrets in this namespace.

Fix `auditor-binding` so it binds the namespaced Role. Do not change either role object, and do
not create a second binding.

## Hint

Search kubernetes.io/docs for **"role binding examples"** - the RBAC reference page's `roleRef`
examples show that `kind` (`Role` vs `ClusterRole`) is what resolves a role name, even when a
Role and a ClusterRole share that name. `auditor-binding` currently sets `roleRef.kind` to
`ClusterRole`, so it follows the ClusterRole instead of the namespaced Role.
