# q107-16-events-sort-by-time: Use kubectl events to find why a pod won't schedule

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-16-events-sort-by-time`

`setup.sh` already created a pod named `big-mem` (image `nginx:1.25-alpine`) in namespace
`q107-16-events-sort-by-time`. The pod is stuck in `Pending` and never starts.

Use `kubectl get events -n q107-16-events-sort-by-time --sort-by=.lastTimestamp` (or
`kubectl describe pod big-mem -n q107-16-events-sort-by-time`) to find the `FailedScheduling`
Warning event that explains why the scheduler can't place this pod, then fix the pod:

- keep the pod named `big-mem` in the same namespace, with the same image (`nginx:1.25-alpine`)
- set the container's `resources.requests.memory` to `64Mi`
- set the container's `resources.limits.memory` to `64Mi`
- the pod reaches and stays in phase `Running`

## Hint

Search kubernetes.io/docs for **"kubectl events sort-by"** - the "Monitor, log, and debug" tasks
show how sorting cluster events by `.lastTimestamp` surfaces the most recent scheduling failures,
including `FailedScheduling` messages like "Insufficient memory".
