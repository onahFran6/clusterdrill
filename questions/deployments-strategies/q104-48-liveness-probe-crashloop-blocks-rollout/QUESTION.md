# q104-48: Stop a livenessProbe from crash-looping the app

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-48-liveness-probe-crashloop-blocks-rollout`

A Deployment named `session-api` already exists in namespace
`q104-48-liveness-probe-crashloop-blocks-rollout` with 2 replicas. Both are stuck in
`CrashLoopBackOff` and the Deployment never reports Ready. The container sleeps briefly before
creating `/tmp/up`, then runs indefinitely; its `livenessProbe` is `exec: ["cat", "/tmp/up"]`.

Without changing the container's command, the probe's `exec` command, `periodSeconds`, or
`failureThreshold`, set `livenessProbe.initialDelaySeconds` to `15`. Confirm both replicas reach
Ready.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the pod
lifecycle docs explain `initialDelaySeconds` as the delay before the very first probe fires. A
livenessProbe that fires before the app finishes starting (especially with a low
`failureThreshold`) kills and restarts the container in a permanent loop - lengthening the
initial delay past startup time breaks that cycle.
