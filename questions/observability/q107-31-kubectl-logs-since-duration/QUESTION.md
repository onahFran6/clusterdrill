# q107-31: Retrieve only recent log lines using a time window, not a line count

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-31-kubectl-logs-since-duration`

`setup.sh` already created a pod named `heartbeat` (image `busybox:1.36`) in this namespace. It
printed one line (`old-line-before-cutoff`) right at startup, then has been printing
`recent-heartbeat` every couple of seconds since.

Using a single `kubectl logs` command with a **time-window** flag (not `--tail`), retrieve only
the log lines from roughly the last 5 seconds, and redirect that output into a file at
`$HOME/practice-work/q107-31-kubectl-logs-since-duration/heartbeat-recent.txt` on the terminal
host (not inside the pod). The resulting file must contain only `recent-heartbeat` lines - the
old startup line must not appear.

## Hint

Search kubernetes.io/docs for **"kubectl logs"** - the kubectl command reference lists `--since`
(a relative duration like `5s`, `2m`) alongside `--since-time` and `--tail`, for filtering log
output by wall-clock recency instead of a fixed line count.
