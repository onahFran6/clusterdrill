# q102-48: Order two dependent native sidecars so the Pod can start

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-48-chained-native-sidecars-startup-order`

A Pod named `chained-sidecars-app` already exists in this namespace with two
native sidecars (init containers with `restartPolicy: Always`) that depend on
each other, plus a main container:

- `cache-warmer` creates `/run/warm/ready` a few seconds after it starts, then
  keeps running.
- `index-builder` has a `startupProbe` that waits for `/run/warm/ready` to
  exist before it is considered started.
- `web` (image `nginx:1.27-alpine`) is the main container.

The Pod is stuck: `kubectl get pod chained-sidecars-app` shows `0/3`,
`Init:0/2`, indefinitely. Native sidecars start in listed order; a later
sidecar that depends on an earlier one's marker will never see that marker if
the order is wrong.

Fix the ordering: `initContainers` must list `cache-warmer` before
`index-builder`. Do not change either container's image, command, or
`startupProbe` - reordering the list is the entire fix. This is immutable on a
running Pod - delete and recreate `chained-sidecars-app` with the fix applied,
keeping every other field unchanged. Once fixed, `chained-sidecars-app` must
reach `3/3 Running` with both native sidecars started.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the Workloads /
Pods concept page's "Sidecar containers" section explains that native
sidecars (init containers with `restartPolicy: Always`) start strictly in
the order listed, each one waiting for its own probe before the next
starts - so a dependency chain between two sidecars must be expressed by
list order, not just by what each one's probe checks.
