# q102-38: Fix a readinessProbe that leaves a healthy app NotReady

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-38-readiness-probe-wrong-container-port`

A Pod named `probe-mixup` already exists in this namespace with two containers:

- `web` (image `nginx:1.27-alpine`) - listens on port `80` and is completely
  healthy.
- `sidecar-metrics` (busybox:1.36) - an unrelated helper container that idles.

`web`'s `readinessProbe` is a `tcpSocket` probe that never succeeds, even
though nginx is healthy and listening on `80`: `kubectl get pod probe-mixup`
shows `1/2`, with `web` stuck `Running` but never `Ready`.

Fix `web`'s `readinessProbe` so it checks the port `web` actually listens on,
`80`. Do not change either container's image or command, and do not touch
`sidecar-metrics`. This field is immutable on a running Pod - delete and
recreate `probe-mixup` with the fix applied, keeping every other field
unchanged. Once fixed, `probe-mixup` must reach `2/2 Running` with `web`
reporting ready.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup
probes"** - the Pods concept page's probes section shows how a
`readinessProbe`'s `tcpSocket.port` (or `httpGet.port`) is checked against
the Pod, and that a probe pointed at a port nothing is listening on never
succeeds, regardless of how healthy the process itself is.
