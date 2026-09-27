# q107-30-log-rotation-container-restart-history: Reconstruct a crash timeline across multiple restarts using logs, describe, and container exit codes

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-30-log-rotation-container-restart-history`

A pod named `flaky-migrator` already exists in namespace
`q107-30-log-rotation-container-restart-history`. It is `Running` and `Ready`, with
`restartCount` at least `2`.

Without changing the pod, write your findings to
`$HOME/practice-work/q107-30-log-rotation-container-restart-history/migrator-diagnosis.txt` on the
terminal host (not inside the pod). The file must contain exactly two lines, in this order:

1. `exit_code=<N>` - the exit code of the container's most recent previous termination, from
   `kubectl get pod flaky-migrator -n q107-30-log-rotation-container-restart-history -o
   jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'`
2. `last_log=<text>` - the last line of the previous container instance's log, from
   `kubectl logs flaky-migrator -n q107-30-log-rotation-container-restart-history --previous`

Do not delete, restart, or otherwise modify `flaky-migrator`. It must still be `Running` and
`Ready` with `restartCount >= 2` when you are done.

## Hint

Search kubernetes.io/docs for **"lastState terminated"** - the Pod Lifecycle page's container
states section explains `lastState`, and the kubectl reference for `kubectl logs` documents the
`-p`/`--previous` flag for reading a terminated container instance's log output before it's gone.
Each start writes a run counter onto an `emptyDir` volume, then fails or succeeds based on that
counter. The current process is sleeping; the failure is only in the previous termination.
