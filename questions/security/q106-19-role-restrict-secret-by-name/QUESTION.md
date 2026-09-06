# q106-19: Grant read access to one named Secret, not all Secrets

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-19-role-restrict-secret-by-name`

`setup.sh` already created, in namespace `q106-19-role-restrict-secret-by-name`:

- a Secret named `db-credentials`
- a second, unrelated Secret named `payment-api-key`
- a ServiceAccount named `report-service`

`report-service` needs to read `db-credentials` only - it must never be able to read
`payment-api-key` or any other Secret that might be added to this namespace later. A Role that
grants `get` on all `secrets` would be too broad here.

Create a Role named `db-credentials-reader` that grants the `get` verb on `secrets`, restricted
to the single resource name `db-credentials` (via `resourceNames`), and a RoleBinding named
`report-service-binding` that grants this Role to the `report-service` ServiceAccount.

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page's "Referring to
resources" section shows how `resourceNames` narrows a rule to specific named objects instead of
every object of that kind.
