# q107-30-log-rotation-container-restart-history: Reconstruct a crash timeline across multiple restarts using logs, describe, and container exit codes

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-30-log-rotation-container-restart-history`

`setup.sh` already created a pod named `flaky-migrator` in namespace
`q107-30-log-rotation-container-restart-history`. Its single container writes a run counter to a
file on an `emptyDir` volume every time it starts, then either fails or succeeds depending on that
counter: it crashed with exit code `1` twice before finally succeeding on its third start, and is
now `Running` and `Ready`, sleeping indefinitely. Its `restartCount` is at least `2`.

Without disturbing the pod's current state, investigate the container's *previous* (failed)
termination and write your findings to a file at
`$HOME/practice-work/q107-30-log-rotation-container-restart-history/migrator-diagnosis.txt` on the
terminal host (not inside the pod). The file must contain **exactly two lines**, in this order:

1. `exit_code=<N>` - the exit code of the container's most recent previous termination, read from
   `kubectl get pod flaky-migrator -n q107-30-log-rotation-container-restart-history -o
   jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'`
2. `last_log=<text>` - the last line of the *previous* container instance's log output, read from
   `kubectl logs flaky-migrator -n q107-30-log-rotation-container-restart-history --previous`

Do not delete, restart, or otherwise modify the `flaky-migrator` pod - it must still be `Running`
and `Ready` with `restartCount >= 2` when you are done.

## Hint

Search kubernetes.io/docs for **"lastState terminated"** - the Pod Lifecycle page's container
states section explains `lastState`, and the kubectl reference for `kubectl logs` documents the
`-p`/`--previous` flag for reading a terminated container instance's log output before it's gone.
