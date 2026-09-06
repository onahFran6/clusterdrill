# q109-42-projected-volume-two-secrets-custom-paths: Combine two Secrets in one projected volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-42-projected-volume-two-secrets-custom-paths`

`setup.sh` already created two Secrets in namespace
`q109-42-projected-volume-two-secrets-custom-paths`:

- `db-credentials` with key `password` (value `hunter2`)
- `api-credentials` with key `token` (value `abc123`)

Create a Pod named `multi-secret-reader` (image `busybox:1.36`, command
`["sh", "-c", "sleep 3600"]`) with a single **projected** volume named `creds`, mounted at
`/etc/creds`, that combines both Secrets with custom item paths so the files end up at:

- `/etc/creds/db/password` (from `db-credentials`'s `password` key)
- `/etc/creds/api/token` (from `api-credentials`'s `token` key)

## Hint

Search kubernetes.io/docs for **"projected volume" "sources"** - the Volumes concept page's
Projected Volumes section shows `spec.volumes[].projected.sources` accepting more than one
`secret` entry in the same projected volume, each with its own `items[].path` to control where
that source's keys land relative to the volume's mount point.
