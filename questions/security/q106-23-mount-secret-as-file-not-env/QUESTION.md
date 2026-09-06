# q106-23-mount-secret-as-file-not-env: Mount a Secret as a file-based volume instead of env vars

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-23-mount-secret-as-file-not-env`

`setup.sh` already created, in namespace `q106-23-mount-secret-as-file-not-env`, a Secret named
`tls-cert` with keys `tls.crt` and `tls.key` (dummy values). No Pod exists yet.

Create a Pod named `cert-reader` using image `busybox:1.36` that runs the command `sleep 3600`.
Mount the `tls-cert` Secret as a volume at `/etc/tls` inside the container, and make that mount
read-only.

## Hint

Search kubernetes.io/docs for **"Distribute Credentials Securely Using Secrets"** - the "Using
Secrets as files from a Pod" section shows how to define a `secret` volume and mount it into a
container.
