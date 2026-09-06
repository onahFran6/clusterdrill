# q105-50-secret-env-vs-volume-rotation: Rotate a Secret and observe env vs volume update behavior

**Domain:** Application Environment, Configuration and Security · **Points:** 6 · **Namespace:** `q105-50-secret-env-vs-volume-rotation`

`setup.sh` already created, in namespace `q105-50-secret-env-vs-volume-rotation`:

- a Secret named `db-creds` with key `PASSWORD=initial-pw`, and
- a running Pod named `credential-consumer` with two containers, both already seeing
  `initial-pw`:
  - `env-reader` gets `DB_PASSWORD` as an environment variable sourced from `db-creds`'s
    `PASSWORD` key via `secretKeyRef`.
  - `vol-reader` mounts `db-creds` as a volume at `/etc/secret`, so `PASSWORD` shows up as a file.

Update `db-creds`'s `PASSWORD` key to `rotated-pw-99`. **Do not delete or recreate the Pod, and do
not `kubectl exec` into either container to change anything by hand.**

An environment variable's value is resolved once, when its container starts - it never changes
for the life of that container, no matter how the Secret it came from is edited afterwards. A
volume mount, by contrast, is refreshed automatically by kubelet's periodic resync. So after you
rotate the Secret and wait, you should expect (and this is what will be checked, not something to
"fix"):

- `vol-reader`'s mounted file to show the **new** value, `rotated-pw-99`, within about a minute,
  and
- `env-reader`'s environment variable to **still** show the **original** value, `initial-pw` -
  that staleness is the correct, expected behavior for an env-var-sourced Secret, not a bug.

## Hint

Search kubernetes.io/docs for **"secrets are mounted"** - the Secrets concept page's note on
mounted Secrets being updated automatically contrasts volume-mounted Secret keys (which refresh
live) with Secret data consumed via environment variables (which are fixed at container start and
never update without a restart).
