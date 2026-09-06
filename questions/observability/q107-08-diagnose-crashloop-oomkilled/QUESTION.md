# q107-08: Diagnose a CrashLoopBackOff caused by an OOMKilled container

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-08-diagnose-crashloop-oomkilled`

`setup.sh` already created a pod named `render-worker` (image `polinux/stress`) in namespace
`q107-08-diagnose-crashloop-oomkilled`. The pod is stuck in `CrashLoopBackOff`. This container's
workload genuinely needs about 150Mi of memory to do its job, but its memory `limit` was set far
too low.

Use `kubectl describe pod render-worker -n q107-08-diagnose-crashloop-oomkilled` to find the
termination reason in the container's last state, then fix the pod:

- keep the pod named `render-worker` in the same namespace
- keep the same image (`polinux/stress`) and the same `command`/`args`
- raise the container's memory `limit` to `256Mi` (and set memory `requests` to `256Mi` too, so the
  pod isn't scheduled expecting less than it needs)
- the pod reaches and stays `Running` with its container `Ready`

## Hint

Search kubernetes.io/docs for **"OOMKilled"** - the "assign memory resources" task page explains how
a container exceeding its memory `limit` gets killed with reason `OOMKilled`, visible in
`describe`'s "Last State" section.
