# q102-49: Capture a crash reason in lastState.terminated.message

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-49-termination-message-policy-hides-crash-reason`

A Pod named `crashy-worker` already exists in this namespace with two
containers:

- `worker` (busybox:1.36) prints
  `FATAL: config file missing at /etc/app/config.yaml` to stdout, then exits
  `1` - and keeps crash-looping.
- `sidecar` (busybox:1.36) - an unrelated second container that idles.

Every time `worker` crashes,
`.status.containerStatuses[].lastState.terminated.message` stays empty, so
`kubectl describe pod crashy-worker` shows nothing useful under "Last State".
This fix does not stop the crash - it makes the crash diagnosable.

Fix `worker` by setting its `terminationMessagePolicy` to
`FallbackToLogsOnError`, so Kubernetes captures the last chunk of `worker`'s
stdout/stderr into `.lastState.terminated.message` when it exits non-zero. Do
not change either container's image or command, and do not touch `sidecar`.
This field is immutable on a running Pod - delete and recreate `crashy-worker`
with the fix applied, keeping every other field unchanged. Once fixed, wait for
`worker` to crash and restart at least once, then
`.status.containerStatuses[?(@.name=="worker")].lastState.terminated.message`
must contain the real diagnostic line.

## Hint

Search kubernetes.io/docs for **"termination message"** - the "Determine
the Reason for Pod Failure" task page shows how a container's
`terminationMessagePolicy` controls whether Kubernetes falls back to
capturing recent log output as the termination message when a container
exits with an error and never wrote to `/dev/termination-log` itself.
