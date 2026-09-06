# q106-06: Bind a ServiceAccount to a Role

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-06-rolebinding-bind-sa-to-role`

`setup.sh` already created, in namespace `q106-06-rolebinding-bind-sa-to-role`:

- a Role named `configmap-reader` (grants `get`/`list` on `configmaps`)
- a ServiceAccount named `config-watcher`

Create a RoleBinding named `config-watcher-binding` that grants the `configmap-reader` Role to
the `config-watcher` ServiceAccount, scoped to this namespace.

## Hint

Search kubernetes.io/docs for **"RoleBinding and ClusterRoleBinding"** - the RBAC concept page
shows the exact `roleRef` and `subjects` shape for binding a ServiceAccount to a Role.
