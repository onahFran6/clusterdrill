# q102-40-prestop-hook-drains-sidecar: Sidecar has no preStop hook, buffered logs would be lost on shutdown

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-40-prestop-hook-drains-sidecar`

A Pod named `batching-shipper` already exists in this namespace with two
containers sharing one `emptyDir` volume named `data`, mounted at `/data`
in both:

- `app` (busybox:1.36) - unrelated to this bug, just idles.
- `log-shipper` (busybox:1.36) - buffers log lines in `/data/buffer.log`
  and only flushes them into `/data/shipped.log` once every 30 seconds.
  Normal steady-state operation is fine.

`log-shipper` has **no `preStop` hook**, and `terminationGracePeriodSeconds`
is left at its low default. When this Pod is deleted, Kubernetes sends
`SIGTERM` immediately and force-kills the container once the grace period
elapses - whatever lines are sitting in `/data/buffer.log`, not yet
flushed, are lost. This never shows up in `kubectl get pod` output; it only
matters at shutdown.

Fix `log-shipper` so no buffered data is lost on shutdown:

- Add a `preStop` lifecycle hook to `log-shipper` that runs
  `sh -c "cat /data/buffer.log >> /data/shipped.log"` (exactly this
  command) to flush any remaining buffered lines before the container
  stops.
- Set the Pod's `terminationGracePeriodSeconds` to at least `15`, so the
  `preStop` hook actually has time to run before `SIGKILL`.

Do not change either container's image or command, and do not touch `app`
at all. These fields are immutable on a running Pod - delete and recreate
`batching-shipper` with the fix applied, keeping every other field
unchanged. Once fixed, `batching-shipper` must still reach `2/2 Running`.

## Hint

Search kubernetes.io/docs for **"attach handlers to container lifecycle
events"** - the Container Lifecycle Hooks concept page shows how a
`preStop` hook runs before a container is terminated, and how
`terminationGracePeriodSeconds` must be long enough for it to finish before
`SIGKILL` is sent.
