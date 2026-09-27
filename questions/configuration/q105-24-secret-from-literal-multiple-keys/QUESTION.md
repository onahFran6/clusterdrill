# q105-24: Create a multi-key Secret so a waiting Pod can start

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-24-secret-from-literal-multiple-keys`

A Pod named `dbclient` (image `nginx:1.25-alpine`) already exists in namespace
`q105-24-secret-from-literal-multiple-keys`. It is stuck in `ContainerCreating` because it expects
a Secret named `db-creds` and needs the Secret's `password` key available as a file at
`/etc/db/password` - but that Secret does not exist yet.

Create the Secret `db-creds` from two literals:

- `username=admin`
- `password=S3cr3t!`

Once the Secret exists with both keys, the pod should start on its own - do not edit the pod.
Only the `password` key must appear as a file inside the container; `username` must not be
exposed inside the container at all (no file, no env var).

## Hint

Search kubernetes.io/docs for **"create secret generic from-literal"** - the Secrets concept page
shows creating a Secret with multiple `--from-literal` key/value pairs in one command.
