# q106-37: Bind a Group to a ClusterRole cluster-wide

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-37-clusterrolebinding-to-group`

`setup.sh` already created a ClusterRole named `q106-37-namespace-viewer` (grants `get`/`list` on
`namespaces`, a cluster-scoped resource, and is already labeled for cleanup).

Create a ClusterRoleBinding named `q106-37-namespace-viewer-binding` that grants the
`q106-37-namespace-viewer` ClusterRole to the **Group** `platform-auditors`, cluster-wide - not a
User or ServiceAccount.

**Important:** label the ClusterRoleBinding you create with
`clusterdrill-question: q106-37-clusterrolebinding-to-group` so cleanup can find it - it is
cluster-scoped and will not be removed just by deleting the namespace.

## Hint

Search kubernetes.io/docs for **"RoleBinding and ClusterRoleBinding"** - the RBAC concept page
shows the three subject kinds a binding can reference (`User`, `Group`, `ServiceAccount`) and the
`--group` flag on `kubectl create clusterrolebinding`.
