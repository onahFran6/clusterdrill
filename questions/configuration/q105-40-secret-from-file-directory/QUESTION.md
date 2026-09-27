# q105-40: Build a Secret from a directory of certificate files

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-40-secret-from-file-directory`

A directory of files already exists at `~/certs/` in your terminal's home directory:

- `~/certs/tls-ca.pem` containing `CA-CERT-DATA`
- `~/certs/tls-client.pem` containing `CLIENT-CERT-DATA`

No Secret exists yet in namespace `q105-40-secret-from-file-directory`.

Create a generic Secret named `cert-bundle` from **every file in `~/certs/` at once** (a single
`--from-file` pointed at the directory, not two separate `--from-file=<path>` flags) so the
Secret ends up with one key per filename - `tls-ca.pem` and `tls-client.pem` - each holding that
file's exact byte content.

## Hint

Search kubernetes.io/docs for **"kubectl create secret generic"** - the kubectl Reference Docs'
`create secret generic` command page shows that pointing `--from-file` at a directory adds one
key per regular file in it, named after the filename.
