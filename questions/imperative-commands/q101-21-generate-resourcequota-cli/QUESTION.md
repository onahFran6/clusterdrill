# q101-21: Generate a ResourceQuota from the CLI, not a manifest

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-21-generate-resourcequota-cli`

Namespace `q101-21-generate-resourcequota-cli` already exists and has no quota applied yet.

Using a single imperative `kubectl create quota` command (no hand-written YAML), create a
ResourceQuota named `build-cap` that caps this namespace at:

- `cpu`: `2`
- `memory`: `2Gi`
- `pods`: `3`

## Hint

Search kubernetes.io/docs for **"kubectl create quota"** - the `kubectl create quota` command
reference shows the `--hard` flag's comma-separated `key=value` syntax.
