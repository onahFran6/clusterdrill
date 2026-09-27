# q106-37: Bind a Group to a ClusterRole cluster-wide

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-37-clusterrolebinding-to-group`

A ClusterRole named `q106-37-namespace-viewer` already exists. It grants `get`/`list` on
`namespaces`.

Create a ClusterRoleBinding named `q106-37-namespace-viewer-binding` that grants the
`q106-37-namespace-viewer` ClusterRole to the Group `platform-auditors`, cluster-wide. The
subject must be a Group, not a User or a ServiceAccount.

Label that ClusterRoleBinding with
`clusterdrill-question: q106-37-clusterrolebinding-to-group`. It is cluster-scoped and will not
be removed just by deleting the namespace.

## Hint

Search kubernetes.io/docs for **"RoleBinding and ClusterRoleBinding"** - the RBAC concept page
shows the three subject kinds a binding can reference (`User`, `Group`, `ServiceAccount`) and the
`--group` flag on `kubectl create clusterrolebinding`.
