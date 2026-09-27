# q107-21-preStop-graceful-shutdown-log: Add a preStop hook so a container logs a shutdown message before terminating

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-21-prestop-graceful-shutdown-log`

A pod named `session-worker` (image `busybox:1.36`, command
`sh -c 'trap : TERM; while true; do sleep 1; done'`) already exists in namespace
`q107-21-prestop-graceful-shutdown-log`.

Edit the pod so it has:

- a `preStop` lifecycle hook on the container that runs the exec command
  `["sh", "-c", "echo shutting down > /tmp/shutdown.log; sleep 2"]`
- `terminationGracePeriodSeconds` set to `10` on the pod spec

Keep the pod named `session-worker`, in the same namespace, with the same image and command.
These fields are immutable on a running pod, so delete and recreate it with the same name. The
pod must end up `Running` and `Ready`.

## Hint

Search kubernetes.io/docs for **"Attach Handlers to Container Lifecycle Events"** - the Define
poststart and prestop handlers task shows the exact `lifecycle.preStop.exec.command` shape, and
the Pod's `terminationGracePeriodSeconds` field controls how long Kubernetes waits for the
preStop hook plus the process itself before force-killing the container. The container traps and
ignores `SIGTERM`, so without the hook a delete would sit until the grace period ended with no
shutdown record. `kubectl get pod session-worker -n q107-21-prestop-graceful-shutdown-log -o yaml`,
edit, delete, and reapply is one way to replace it.
