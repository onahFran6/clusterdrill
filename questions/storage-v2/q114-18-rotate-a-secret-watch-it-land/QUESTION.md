# q114-18: Rotate a Secret, watch it land

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-18-rotate-a-secret-watch-it-land`

Deployment `api` reads Secret `api-token` both as env var `TOKEN` and as mounted file
`/etc/token/value`. Every 5 seconds it appends `env=<TOKEN> file=<file>` to `/audit/log` on claim
`audit`.

- Rotate the Secret's `value` from `v1` to `v2` using the create/dry-run/apply pattern, **without**
  restarting anything.
- `(ungraded)` After roughly 90 seconds, read the log's newest line - the env var still reads the
  old value while the mounted file has already refreshed. Then `kubectl rollout restart` and
  confirm the log's newest line now shows the rotated value on both sides.
- Confirm the claim kept every earlier line.

## Hint

Search kubernetes.io/docs for **"Mounted ConfigMaps are updated automatically"** on the Secrets
concept page - the same mechanism applies to Secret volumes. Predict each value after the
rotation: when is an env var read, and how does a mounted Secret file get refreshed? Why does the
log survive the restart?
