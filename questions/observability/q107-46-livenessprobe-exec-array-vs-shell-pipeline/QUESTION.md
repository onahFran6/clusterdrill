# q107-46: Fix a livenessProbe that tries to pipe two commands without a shell

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-46-livenessprobe-exec-array-vs-shell-pipeline`

`setup.sh` already created a Pod named `status-writer` (image `busybox:1.36`) that continuously
writes `ok` to `/tmp/status` - it is genuinely healthy. Its `livenessProbe` is
`exec: command: ["cat", "/tmp/status", "|", "grep", "ok"]`, and it's crash-looping anyway: an exec
probe's command array runs the program directly with no shell, so `|` is passed to `cat` as a
literal filename argument instead of being interpreted as a pipe, and `cat` fails trying to open
files that don't exist.

Fix `status-writer`'s `livenessProbe` so the pipeline actually works, without changing the
container's own command or image, and confirm it stops restarting (`restartCount` stays `0`).

## Hint

Search kubernetes.io/docs for **"define a liveness command"** - the probes task page's `exec`
example is a single command with no pipe; to run shell syntax like a pipeline inside an exec
probe, the command array itself must invoke a shell (e.g. `["sh", "-c", "..."]`).
