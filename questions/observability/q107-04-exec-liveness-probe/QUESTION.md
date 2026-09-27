# q107-04: Add a command-based (exec) liveness probe for a pod with no HTTP endpoint

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-04-exec-liveness-probe`

A pod named `file-watcher` (image `busybox:1.36`) already exists in namespace
`q107-04-exec-liveness-probe`. Its container runs `sh -c "touch /tmp/healthy && sleep 3600"` and
has no probes.

Edit the pod so it has a `livenessProbe` that:

- uses `exec` to run the command `cat /tmp/healthy`
- sets `initialDelaySeconds` to `5`
- sets `periodSeconds` to `10`

Keep the pod named `file-watcher`, keep the same container command, and keep it running (you may
delete and recreate it with the same name to add the probe).

## Hint

Search kubernetes.io/docs for **"define a liveness command"** - the probes task page shows the
`exec.command` list form for running an arbitrary command inside the container as the health
check. This workload has no HTTP port, so liveness has to be a command rather than `httpGet`.
