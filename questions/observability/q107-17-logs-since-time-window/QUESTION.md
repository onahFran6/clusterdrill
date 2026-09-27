# q107-17-logs-since-time-window: Retrieve only the last N lines of logs from a noisy container

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-17-logs-since-time-window`

A pod named `ticker` (image `busybox:1.36`) already exists in namespace
`q107-17-logs-since-time-window`. Its container keeps printing lines that look like `tick <N>`.

Save only the most recent 5 lines of that log to
`$HOME/practice-work/q107-17-logs-since-time-window/ticker-tail.txt` on the terminal host (not
inside the pod). The file must contain exactly 5 lines, each matching `tick <N>`, and they must
be the end of the log (the last line's number greater than the first line's number), not the
first 5 lines ever printed.

## Hint

Search kubernetes.io/docs for **"kubectl logs --tail"** - the kubectl reference for `kubectl logs`
shows the `--tail` flag that limits output to the most recent N lines of a container's log, as
opposed to `--since`/`--since-time` which filter by wall-clock time. For example:

```sh
kubectl logs ticker -n q107-17-logs-since-time-window --tail=5 \
  > "$HOME/practice-work/q107-17-logs-since-time-window/ticker-tail.txt"
```
