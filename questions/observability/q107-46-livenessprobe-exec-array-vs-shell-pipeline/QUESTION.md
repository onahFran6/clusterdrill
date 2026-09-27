# q107-46: Fix a livenessProbe that tries to pipe two commands without a shell

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-46-livenessprobe-exec-array-vs-shell-pipeline`

A Pod named `status-writer` (image `busybox:1.36`) already exists. It continuously writes `ok` to
`/tmp/status` and is otherwise healthy, but its `livenessProbe` is crash-looping the container.

Fix the `livenessProbe` so the container stays up. Do not change the container's command or image.
`restartCount` must stay `0`.

## Hint

Search kubernetes.io/docs for **"define a liveness command"** - the probes task page's `exec`
example is a single command with no pipe; to run shell syntax like a pipeline inside an exec
probe, the command array itself must invoke a shell (e.g. `["sh", "-c", "..."]`). The current
probe is `exec: command: ["cat", "/tmp/status", "|", "grep", "ok"]`. An exec probe runs the
program directly, so `|` is a literal argument to `cat`, not a pipe, and `cat` fails opening
files that do not exist.
