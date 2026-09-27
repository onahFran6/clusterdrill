# q106-20: Revoke an over-broad Secrets grant

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-20-serviceaccount-no-secret-access`

ServiceAccount `web-frontend` in namespace `q106-20-serviceaccount-no-secret-access` can read
every Secret in the namespace, through Role `all-secrets-reader` and RoleBinding
`web-frontend-all-secrets`. The frontend never reads Secrets. That access must be removed.

Remove whatever grants `web-frontend` any access to `secrets` in this namespace. Do not delete
the `web-frontend` ServiceAccount itself.

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page shows how a
RoleBinding is what actually grants a Role's permissions to a subject, and that deleting the
binding (or the rule) revokes the grant.
