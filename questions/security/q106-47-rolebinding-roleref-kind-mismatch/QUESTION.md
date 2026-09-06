# q106-47: Fix a RoleBinding resolving to the wrong same-named role kind

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-47-rolebinding-roleref-kind-mismatch`

`setup.sh` already created, in this namespace: a ServiceAccount named `auditor`; a Role named
`q106-47-secret-reader` (grants `get`/`list` on `secrets`); a **ClusterRole**, also named
`q106-47-secret-reader` but granting only `get` on `configmaps` cluster-wide (a decoy - Kubernetes
allows a `Role` and a `ClusterRole` to share the exact same name); and a RoleBinding named
`auditor-binding` whose `roleRef.kind` is currently `ClusterRole`, so it resolves to the decoy
instead of the Role. Fix `auditor-binding` so it correctly binds the namespaced **Role** instead,
without touching either role object or creating a second binding.

## Hint

Search kubernetes.io/docs for **"role binding examples"** - the RBAC reference page's `roleRef`
examples show that `kind` (`Role` vs `ClusterRole`) is what a binding uses to resolve a role name,
independent of what namespace-scoped object with that name might also exist.
