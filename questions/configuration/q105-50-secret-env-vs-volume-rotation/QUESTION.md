# q105-50-secret-env-vs-volume-rotation: Rotate a Secret and observe env vs volume update behavior

**Domain:** Application Environment, Configuration and Security · **Points:** 6 · **Namespace:** `q105-50-secret-env-vs-volume-rotation`

In namespace `q105-50-secret-env-vs-volume-rotation`:

- a Secret named `db-creds` with key `PASSWORD=initial-pw` already exists, and
- a running Pod named `credential-consumer` with two containers, both already seeing
  `initial-pw`:
  - `env-reader` gets `DB_PASSWORD` as an environment variable sourced from `db-creds`'s
    `PASSWORD` key via `secretKeyRef`.
  - `vol-reader` mounts `db-creds` as a volume at `/etc/secret`, so `PASSWORD` shows up as a file.

Update `db-creds`'s `PASSWORD` key to `rotated-pw-99`. **Do not delete or recreate the Pod, and do
not change either container's content by hand.**

After you rotate the Secret and wait, you should expect (and this is what will be checked):

- `vol-reader`'s mounted file to show the **new** value, `rotated-pw-99`, within about a minute,
  and
- `env-reader`'s environment variable to **still** show the **original** value, `initial-pw`.

## Hint

Search kubernetes.io/docs for **"secrets are mounted"** - the Secrets concept page's note on
mounted Secrets being updated automatically contrasts volume-mounted Secret keys (which kubelet
refreshes live) with Secret data consumed via environment variables (resolved once at container
start and never updated without a restart). That env-var staleness after a Secret rotation is
expected behavior, not a bug.
