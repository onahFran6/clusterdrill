# q104-48-liveness-probe-crashloop-blocks-rollout: Fix a livenessProbe that's too aggressive to let the app start

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-48-liveness-probe-crashloop-blocks-rollout`

`setup.sh` already created a Deployment named `session-api` in namespace
`q104-48-liveness-probe-crashloop-blocks-rollout` with 2 replicas. Its container's command sleeps
for 8 seconds before creating the file `/tmp/up` and then runs indefinitely - a stand-in for an
app that needs a few seconds to finish starting up. Its `livenessProbe` is `exec: command: ["cat",
"/tmp/up"]`, with `initialDelaySeconds: 0` and `failureThreshold: 1`.

That combination never gives the app a chance: the very first liveness check fires before
`/tmp/up` exists, `failureThreshold: 1` means one failure is enough, and the kubelet kills and
restarts the container - which then hits the exact same timing problem again, forever. Both
replicas are stuck `CrashLoopBackOff` and the Deployment never reports Ready.

Without changing the container's command, the probe's `exec` command, `periodSeconds`, or
`failureThreshold`, fix `session-api`'s `livenessProbe.initialDelaySeconds` to `15` - safely past
the 8-second startup window - and confirm both replicas reach Ready.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the pod
lifecycle docs explain `initialDelaySeconds` as the delay before the very first probe fires, and
warn that a livenessProbe with too short a delay (or too low a `failureThreshold`) can kill a
container before it finishes starting, causing a permanent restart loop.
