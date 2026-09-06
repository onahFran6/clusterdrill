# q106-20: Revoke an over-broad Secrets grant

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-20-serviceaccount-no-secret-access`

A security audit found that the ServiceAccount `web-frontend` (already created by `setup.sh` in
namespace `q106-20-serviceaccount-no-secret-access`) was mistakenly granted blanket read access to
every Secret in the namespace, via a Role named `all-secrets-reader` and a RoleBinding named
`web-frontend-all-secrets`. The frontend never reads Secrets directly at all - this access has no
legitimate use and must be removed entirely.

Remove whatever grants `web-frontend` any access to `secrets` in this namespace, without deleting
the `web-frontend` ServiceAccount itself (it is still needed for other, unrelated permissions it
holds).

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page shows how a
RoleBinding is what actually grants a Role's permissions to a subject, and that deleting the
binding (or the rule) revokes the grant.
