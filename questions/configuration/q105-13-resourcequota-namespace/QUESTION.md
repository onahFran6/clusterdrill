# q105-13: Cap total namespace resource consumption with a ResourceQuota

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-13-resourcequota-namespace`

Namespace `q105-13-resourcequota-namespace` already exists but has no `ResourceQuota` yet.

Create a `ResourceQuota` named `team-quota` in that namespace that caps the namespace's total
resource consumption at:

- `requests.cpu`: `1`
- `requests.memory`: `1Gi`
- `limits.cpu`: `2`
- `limits.memory`: `2Gi`
- `pods`: `5`

## Hint

Search kubernetes.io/docs for **"resource quota"** - the Resource Quotas concept page shows the
`ResourceQuota` object's `spec.hard` field and the standard resource names it accepts
(`requests.cpu`, `limits.memory`, `pods`, etc.).
