# q102-27: Native sidecar's startupProbe gates the main container

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-27-native-sidecar-startupprobe-gates-main`

A Pod named `gated-app` already exists with two containers:

- An **init container** named `cache-warmer` (image `busybox:1.36`) with
  `restartPolicy: Always` set on the container itself - a native sidecar
  (KEP-753). It creates the marker file `/var/run/warmer/ready` a few
  seconds after starting, then keeps running for the life of the Pod. It
  also has a `startupProbe` that runs an `exec` command inside it.
- A main container named `web` (image `nginx:1.27-alpine`).

The Pod is stuck: `kubectl get pod gated-app` shows `0/2` and never
progresses past `Init:0/1`, but `cache-warmer` itself is not crashing from
its own command - it keeps being restarted by the kubelet because its
`startupProbe` never succeeds. Since Kubernetes will not start a Pod's main
containers until every native sidecar (an init container with
`restartPolicy: Always`) has passed its own `startupProbe`, `web` never
starts either - it is not `web`'s fault, and nothing about `web`'s own spec
is broken.

Find why `cache-warmer`'s `startupProbe` never succeeds and fix it so that
it actually observes the file `cache-warmer` creates. Because Pod fields
like `startupProbe` are immutable on a running Pod, you will need to delete
and recreate `gated-app` with the fix applied. Do not change either
container's image or command, and do not change `cache-warmer`'s
`restartPolicy`. When you are done, `gated-app` must show `2/2 Running`
with both containers reporting `started: true`.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the Workloads /
Pods concept page's "Sidecar containers" section explains that a native
sidecar (an init container with `restartPolicy: Always`) must pass its own
probes before the Pod's regular containers are started, and shows the
`startupProbe` field this depends on.
