# q102-48-chained-native-sidecars-startup-order: Two dependent native sidecars listed in the wrong order

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-48-chained-native-sidecars-startup-order`

A Pod named `chained-sidecars-app` already exists in this namespace with
two native sidecars (init containers with `restartPolicy: Always`) that
depend on each other, plus a main container:

- `cache-warmer` creates the marker file `/run/warm/ready` a few seconds
  after it starts, then keeps running.
- `index-builder` has a `startupProbe` that waits for
  `/run/warm/ready` to exist before it is considered started.
- `web` (image `nginx:1.27-alpine`) is the main container.

Kubernetes starts native sidecars **in the order they're listed**, only
starting the next one once the current one's own `startupProbe` has
passed. `index-builder` is listed **before** `cache-warmer` in
`initContainers`, so `index-builder` starts first - and its `startupProbe`
waits forever for `/run/warm/ready`, a file only `cache-warmer` can create,
and `cache-warmer` never even gets a chance to start. The whole Pod is
stuck: `kubectl get pod chained-sidecars-app` shows `0/3`, `Init:0/2`,
indefinitely - this is not `web`'s fault, and nothing about either
sidecar's own image, command, or probe command is broken.

Fix the ordering: `initContainers` must list `cache-warmer` **before**
`index-builder`, so `cache-warmer` starts first, passes its own
`startupProbe` (it has none, so it starts immediately), creates the marker
file, and only then does `index-builder` start and find the file already
there. Do not change either container's image, command, or `startupProbe`
- reordering the list is the entire fix. This is immutable on a running
Pod - delete and recreate `chained-sidecars-app` with the fix applied,
keeping every other field unchanged. Once fixed, `chained-sidecars-app`
must reach `3/3 Running` with both native sidecars started.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the Workloads /
Pods concept page's "Sidecar containers" section explains that native
sidecars (init containers with `restartPolicy: Always`) start strictly in
the order listed, each one waiting for its own probe before the next
starts - so a dependency chain between two sidecars must be expressed by
list order, not just by what each one's probe checks.
