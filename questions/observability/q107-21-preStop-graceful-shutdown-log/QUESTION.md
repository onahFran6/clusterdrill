# q107-21-preStop-graceful-shutdown-log: Add a preStop hook so a container logs a shutdown message before terminating

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-21-prestop-graceful-shutdown-log`

`setup.sh` already created a pod named `session-worker` (image `busybox:1.36`, command
`sh -c 'trap : TERM; while true; do sleep 1; done'`) in namespace
`q107-21-prestop-graceful-shutdown-log`. The container traps and ignores `SIGTERM`, so on
deletion it would otherwise keep running until the full termination grace period elapses with
no record of a graceful shutdown ever being attempted.

Edit the pod so it has:

- a `preStop` lifecycle hook on the container that runs the exec command
  `["sh", "-c", "echo shutting down > /tmp/shutdown.log; sleep 2"]`
- `terminationGracePeriodSeconds` set to `10` on the pod spec

Keep the pod named `session-worker`, in the same namespace, with the same image and command
(these lifecycle/grace-period fields are immutable on a running pod, so you must delete and
recreate it - e.g. `kubectl get pod session-worker -n q107-21-prestop-graceful-shutdown-log -o yaml`,
edit, then reapply with the same name). The pod must end up `Running` and `Ready`.

## Hint

Search kubernetes.io/docs for **"Attach Handlers to Container Lifecycle Events"** - the Define
poststart and prestop handlers task shows the exact `lifecycle.preStop.exec.command` shape, and
the Pod's `terminationGracePeriodSeconds` field controls how long Kubernetes waits for the
preStop hook plus the process itself before force-killing the container.
