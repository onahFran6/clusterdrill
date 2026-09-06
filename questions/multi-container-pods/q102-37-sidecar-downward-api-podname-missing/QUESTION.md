# q102-37-sidecar-downward-api-podname-missing: Sidecar tags shipped logs with "unknown-pod"

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-37-sidecar-downward-api-podname-missing`

A Pod named `tagged-shipper` already exists in this namespace with two
containers sharing one `emptyDir` volume named `logs`, mounted at `/logs`
in both:

- `app` (busybox:1.36) writes a heartbeat line to `/logs/app.log`, prefixed
  with its own `POD_NAME` environment variable - populated correctly via
  the Downward API (`valueFrom.fieldRef.fieldPath: metadata.name`).
- `shipper` (busybox:1.36) is supposed to copy `/logs/app.log` into
  `/logs/shipped.log`, prefixed with `[$POD_NAME]` so a downstream log
  aggregator can tell which Pod every shipped line came from.

`shipper`'s container spec has no `POD_NAME` environment variable defined
at all - unlike `app`, it never sets up the Downward API `fieldRef` for it -
so `${POD_NAME:-unknown-pod}` always falls back to the literal string
`unknown-pod`. Nothing crashes; `kubectl get pod tagged-shipper` shows
`2/2 Running` the whole time, but every line `shipper` writes to
`/logs/shipped.log` is tagged with the wrong, generic pod name.

Add a `POD_NAME` environment variable to `shipper`'s container spec that
uses the Downward API to expose the Pod's own `metadata.name`, the same way
`app` already does. Do not change either container's image or command, and
do not hardcode the Pod's name as a literal string - it must come from the
Downward API. This field is immutable on a running Pod - delete and
recreate `tagged-shipper` with the fix applied, keeping every other field
unchanged. Once fixed, `/logs/shipped.log` inside `shipper` must contain
`[tagged-shipper] tagged-shipper: request handled`.

## Hint

Search kubernetes.io/docs for **"expose pod information to containers
through environment variables"** - the Downward API task page shows how
`env[].valueFrom.fieldRef.fieldPath: metadata.name` exposes a Pod's own
name to a container as an environment variable.
