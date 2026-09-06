# q102-50-livenessprobe-wrong-path-crashloop: Healthy app killed on repeat by its own mistyped livenessProbe

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-50-livenessprobe-wrong-path-crashloop`

A Pod named `false-alarm-app` already exists in this namespace with two
containers:

- `app` (busybox:1.36) touches `/tmp/healthy` every 2 seconds, forever - it
  is completely healthy and never stops doing this.
- `sidecar` (busybox:1.36) - an unrelated second container, not part of
  this bug, just idles.

`app`'s `livenessProbe` execs `test -f /tmp/health` - missing the trailing
`y` - a path that never exists. The probe always fails, so the kubelet
repeatedly kills and restarts `app` on a perfectly healthy process:
`kubectl get pod false-alarm-app` shows a rising `RESTARTS` count and
`CrashLoopBackOff`, even though nothing is actually wrong with `app`
itself.

Fix `app`'s `livenessProbe` so it execs `test -f /tmp/healthy` (the real
path `app` actually maintains), instead of `/tmp/health`. Do not change
either container's image or command, and do not touch `sidecar` at all.
This field is immutable on a running Pod - delete and recreate
`false-alarm-app` with the fix applied, keeping every other field
unchanged. Once fixed, `false-alarm-app` must reach `2/2 Running` and stay
there without restarting `app` again.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup
probes"** - the Pods concept page's probes section shows that a
`livenessProbe` failing repeatedly causes the kubelet to restart the
container, regardless of whether the application process itself is
actually unhealthy - the probe command has to be correct for the signal
to mean anything.
