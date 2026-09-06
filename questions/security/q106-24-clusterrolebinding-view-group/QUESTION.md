# q106-24-clusterrolebinding-view-group: Bind the built-in `view` ClusterRole to a ServiceAccount for read-only cluster access

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-24-clusterrolebinding-view-group`

`setup.sh` already created, in namespace `q106-24-clusterrolebinding-view-group`:

- a ServiceAccount named `auditor` with no permissions granted

Create a ClusterRoleBinding named `auditor-view-binding` that grants the built-in `view`
ClusterRole to the `auditor` ServiceAccount, cluster-wide.

**Important:** label the ClusterRoleBinding you create with
`clusterdrill-question: q106-24-clusterrolebinding-view-group` so cleanup can find it - it is
cluster-scoped and will not be removed just by deleting the namespace.

## Hint

Search kubernetes.io/docs for **"user-facing roles"** - the RBAC concept page describes the
built-in `view` ClusterRole and how a `ClusterRoleBinding`'s `subjects` can reference a
ServiceAccount that lives in any one namespace while the grant itself applies cluster-wide.
