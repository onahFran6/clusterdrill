# q107-09: Retrieve logs from one specific container in a multi-container pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-09-multicontainer-logs-dash-c`

`setup.sh` already created a pod named `order-pipeline` in namespace
`q107-09-multicontainer-logs-dash-c` with two containers: `producer` and `consumer`. Only the
`consumer` container prints a one-time startup line containing a secret token to its stdout; `-n
pod logs` for a multi-container pod without specifying a container fails outright, so you have to
target the right one explicitly.

Find the line the `consumer` container printed at startup (it looks like
`CONSUMER_TOKEN=<some-value>`), then record that exact token value in a ConfigMap:

- create a ConfigMap named `found-token` in namespace `q107-09-multicontainer-logs-dash-c`
- with a single key `token` whose value is the token you read from the `consumer` container's logs
  (the value after `CONSUMER_TOKEN=`, nothing else)

## Hint

Search kubernetes.io/docs for **"kubectl logs"** - the kubectl reference page's `logs` command
shows the `-c`/`--container` flag needed to pick one container's log stream out of a pod that runs
more than one.
