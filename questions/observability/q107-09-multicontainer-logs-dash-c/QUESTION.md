# q107-09: Retrieve logs from one specific container in a multi-container pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-09-multicontainer-logs-dash-c`

A pod named `order-pipeline` already exists in namespace `q107-09-multicontainer-logs-dash-c`
with two containers: `producer` and `consumer`. The `consumer` container prints a one-time startup
line `CONSUMER_TOKEN=<some-value>`.

Record that token in a ConfigMap:

- create a ConfigMap named `found-token` in namespace `q107-09-multicontainer-logs-dash-c`
- with a single key `token` whose value is the token from the `consumer` container's logs
  (the value after `CONSUMER_TOKEN=`, nothing else)

## Hint

Search kubernetes.io/docs for **"kubectl logs"** - the kubectl reference page's `logs` command
shows the `-c`/`--container` flag needed to pick one container's log stream out of a pod that runs
more than one. `kubectl logs` on a multi-container pod fails until you name the container.
