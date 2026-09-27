# q107-10: Recover a message from a container's previous run before it restarted

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-10-logs-previous-container-restart`

A pod named `flaky-init` already exists in namespace `q107-10-logs-previous-container-restart`.
Its container crashed once on its first run (printing a one-time diagnostic line) and has since
restarted into a stable `Running` state. That line is only in the previous run's logs.

Find the line `INIT_FAILURE_CODE=<some-value>` from the container's previous run, then record it
in a ConfigMap:

- create a ConfigMap named `recovered-log` in namespace `q107-10-logs-previous-container-restart`
- with a single key `code` whose value is the code you read (the value after
  `INIT_FAILURE_CODE=`, nothing else)

## Hint

Search kubernetes.io/docs for **"kubectl logs"** - the kubectl reference page's `logs` command
documents the `-p`/`--previous` flag for printing logs from a container instance that has already
terminated, which is exactly what a restarted container's first run becomes. The current process
no longer has that startup line in its output.
