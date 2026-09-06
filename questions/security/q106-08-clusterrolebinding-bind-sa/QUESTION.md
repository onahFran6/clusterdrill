# q106-08: Bind a ServiceAccount to a ClusterRole cluster-wide

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-08-clusterrolebinding-bind-sa`

`setup.sh` already created, in namespace `q106-08-clusterrolebinding-bind-sa`:

- a ServiceAccount named `fleet-inspector`
- a ClusterRole named `q106-08-namespace-viewer` (grants `get`/`list` on `namespaces`, a
  cluster-scoped resource, and is already labeled for cleanup)

Create a ClusterRoleBinding named `q106-08-fleet-inspector-binding` that grants the
`q106-08-namespace-viewer` ClusterRole to the `fleet-inspector` ServiceAccount, cluster-wide.

**Important:** label the ClusterRoleBinding you create with
`clusterdrill-question: q106-08-clusterrolebinding-bind-sa` so cleanup can find it - it is
cluster-scoped and will not be removed just by deleting the namespace.

## Hint

Search kubernetes.io/docs for **"RoleBinding and ClusterRoleBinding"** - the RBAC concept page
shows how a `ClusterRoleBinding`'s `subjects` can reference a ServiceAccount that lives in any
one namespace while the grant itself applies cluster-wide.
