# q106-35: Create a generic Secret from two literal values

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-35-secret-from-literal-two-keys`

Create a generic Secret named `api-keys` in this namespace with exactly two keys:

- `PRIMARY_KEY` = `primary-key-123`
- `SECONDARY_KEY` = `backup-key-124`

## Hint

Search kubernetes.io/docs for **"create secret using kubectl"** - the Secrets concept page shows
the `--from-literal` flag for creating a generic Secret with one or more key/value pairs directly
on the command line.
