# q106-36: Grant a ServiceAccount read access to pods and pod logs

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-36-role-multiple-resources-verbs`

A ServiceAccount named `log-viewer` already exists in this namespace. Create a Role and RoleBinding
so that `log-viewer` can `get`, `list`, and `watch` Pods, and `get` Pod logs (`pods/log`) - but
nothing more (it must not be able to delete Pods).

## Hint

Search kubernetes.io/docs for **"role and clusterrole"** - the RBAC reference page shows how a
single Role's `rules` list can grant different verbs to different resources, including the
`pods/log` subresource.
