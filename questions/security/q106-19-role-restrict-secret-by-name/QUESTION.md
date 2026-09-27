# q106-19: Grant read access to one named Secret, not all Secrets

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-19-role-restrict-secret-by-name`

Namespace `q106-19-role-restrict-secret-by-name` already has:

- a Secret named `db-credentials`
- a second Secret named `payment-api-key`
- a ServiceAccount named `report-service`

`report-service` must be able to `get` Secret `db-credentials` only. It must not be able to read
`payment-api-key` or any other Secret in this namespace.

Create a Role named `db-credentials-reader` that grants `get` on `secrets`, limited to the
resource name `db-credentials` (`resourceNames`), and a RoleBinding named `report-service-binding`
that grants this Role to the `report-service` ServiceAccount.

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page's "Referring to
resources" section shows how `resourceNames` narrows a rule to specific named objects instead of
every object of that kind. A rule that grants `get` on all `secrets` is too broad for this task.
