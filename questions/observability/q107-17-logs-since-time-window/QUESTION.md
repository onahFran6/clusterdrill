# q107-17-logs-since-time-window: Retrieve only the last N lines of logs from a noisy container

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-17-logs-since-time-window`

`setup.sh` already created a pod named `ticker` (image `busybox:1.36`) in namespace
`q107-17-logs-since-time-window`. Its single container never stops printing - it has already
produced a long scrollback of lines that each look like `tick <N>` (one per second) by the time
you look at it.

Retrieve **only the most recent 5 lines** of the `ticker` container's log with a single
`kubectl logs` command, and redirect that output into a file at
`$HOME/practice-work/q107-17-logs-since-time-window/ticker-tail.txt` on the terminal host (not
inside the pod). For example:

```sh
kubectl logs ticker -n q107-17-logs-since-time-window --tail=5 \
  > "$HOME/practice-work/q107-17-logs-since-time-window/ticker-tail.txt"
```

The resulting file must contain exactly 5 lines, each matching `tick <N>`, and they must be the
*end* of the log (the last line's number must be greater than the first line's number) - not the
first 5 lines ever printed.

## Hint

Search kubernetes.io/docs for **"kubectl logs --tail"** - the kubectl reference for `kubectl logs`
shows the `--tail` flag that limits output to the most recent N lines of a container's log, as
opposed to `--since`/`--since-time` which filter by wall-clock time.
