# q102-39-ambassador-missing-readiness-probe: Ambassador has no readinessProbe, marked ready before it's listening

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-39-ambassador-missing-readiness-probe`

A Pod named `ambassador-app` already exists in this namespace with two
containers:

- `app` (busybox:1.36) - the main application container, unrelated to this
  bug, just idles.
- `ambassador` (busybox:1.36) - a TCP proxy container that listens on port
  `8080`, but takes a few seconds after the container starts before it is
  actually listening.

`ambassador` has no `readinessProbe` at all, so Kubernetes marks it (and
therefore the Pod as a whole) `Ready` the instant the container process
starts - not once it is actually accepting connections on `8080`. Any
traffic routed to the Pod during that startup window would be refused,
even though `kubectl get pod ambassador-app` already shows `2/2 Running`.

Add a `readinessProbe` to `ambassador` that checks TCP port `8080`, so the
Pod is only marked ready once `ambassador` is truly accepting connections.
Do not change either container's image or command, and do not touch `app`
at all. This field is immutable on a running Pod - delete and recreate
`ambassador-app` with the fix applied, keeping every other field unchanged.
Once fixed, `ambassador-app` must reach `2/2 Running` with `ambassador`
reporting ready.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup
probes"** - the Pods concept page's probes section shows how a
`readinessProbe` (unlike a bare "the process started") tells Kubernetes a
container is actually ready to serve traffic, and that a container with no
readinessProbe at all is considered ready as soon as it starts.
