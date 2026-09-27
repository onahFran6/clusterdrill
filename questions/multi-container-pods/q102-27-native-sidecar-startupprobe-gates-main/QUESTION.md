# q102-27: Unstick a native sidecar blocked by its startupProbe

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-27-native-sidecar-startupprobe-gates-main`

A Pod named `gated-app` already exists with two containers:

- An init container named `cache-warmer` (image `busybox:1.36`) with
  `restartPolicy: Always` - a native sidecar. It creates `/var/run/warmer/ready`
  a few seconds after starting, then keeps running. It also has a
  `startupProbe` that runs an `exec` command inside it.
- A main container named `web` (image `nginx:1.27-alpine`).

The Pod is stuck: `kubectl get pod gated-app` shows `0/2` and never progresses
past `Init:0/1`. `cache-warmer` keeps being restarted by the kubelet because its
`startupProbe` never succeeds, so `web` never starts either.

Find why `cache-warmer`'s `startupProbe` never succeeds and fix it so the probe
observes the file `cache-warmer` creates. Because fields like `startupProbe`
are immutable on a running Pod, delete and recreate `gated-app` with the fix.
Do not change either container's image or command, and do not change
`cache-warmer`'s `restartPolicy`. When done, `gated-app` must show `2/2 Running`
with both containers reporting `started: true`.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the Workloads /
Pods concept page's "Sidecar containers" section explains that a native
sidecar (an init container with `restartPolicy: Always`) must pass its own
probes before the Pod's regular containers are started, and shows the
`startupProbe` field this depends on.
