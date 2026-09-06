# q105-24-secret-from-literal-multiple-keys: Create a multi-key Secret from literals and mount only one key

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-24-secret-from-literal-multiple-keys`

`setup.sh` already applied a pod named `dbclient` (image `nginx:1.25-alpine`) in namespace
`q105-24-secret-from-literal-multiple-keys`. The pod is stuck in `ContainerCreating` because it
mounts one key (`password`) of a Secret named `db-creds` as a file at `/etc/db/password` via
`subPath`, and that Secret does not exist yet.

Create the Secret `db-creds` imperatively from two literals:

- `username=admin`
- `password=S3cr3t!`

Once the Secret exists with both keys, the pod's existing volume/subPath configuration will let
it start on its own - do not edit the pod. Only the `password` key must ever appear as a file or
environment variable anywhere in the pod; `username` must not be exposed inside the container at
all (no file, no env var).

## Hint

Search kubernetes.io/docs for **"create secret generic from-literal"** - the Secrets concept page
shows creating a Secret with multiple `--from-literal` key/value pairs in one command.
