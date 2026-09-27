# q102-50: Stop a livenessProbe from crash-looping a healthy app

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-50-livenessprobe-wrong-path-crashloop`

A Pod named `false-alarm-app` already exists in this namespace with two
containers:

- `app` (busybox:1.36) touches `/tmp/healthy` every 2 seconds, forever - it is
  completely healthy and never stops doing this.
- `sidecar` (busybox:1.36) - an unrelated second container that idles.

`app`'s `livenessProbe` keeps failing, so the kubelet repeatedly kills and
restarts a healthy process: `kubectl get pod false-alarm-app` shows a rising
`RESTARTS` count and `CrashLoopBackOff`.

Fix `app`'s `livenessProbe` so it execs `test -f /tmp/healthy` (the path `app`
actually maintains). Do not change either container's image or command, and do
not touch `sidecar`. This field is immutable on a running Pod - delete and
recreate `false-alarm-app` with the fix applied, keeping every other field
unchanged. Once fixed, `false-alarm-app` must reach `2/2 Running` and stay
there without restarting `app` again.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup
probes"** - the Pods concept page's probes section shows that a
`livenessProbe` failing repeatedly causes the kubelet to restart the
container, regardless of whether the application process itself is
actually unhealthy - the probe command has to be correct for the signal
to mean anything.
