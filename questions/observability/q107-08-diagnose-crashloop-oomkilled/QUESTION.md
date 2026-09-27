# q107-08: Diagnose a CrashLoopBackOff caused by an OOMKilled container

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-08-diagnose-crashloop-oomkilled`

A pod named `render-worker` (image `polinux/stress`) already exists in namespace
`q107-08-diagnose-crashloop-oomkilled`. The pod is stuck in `CrashLoopBackOff`.

Find the termination reason in the container's last state, then fix the pod:

- keep the pod named `render-worker` in the same namespace
- keep the same image (`polinux/stress`) and the same `command`/`args`
- set the container's memory `limit` to `256Mi` and its memory `requests` to `256Mi`
- the pod reaches and stays `Running` with its container `Ready`

## Hint

Search kubernetes.io/docs for **"OOMKilled"** - the "assign memory resources" task page explains how
a container exceeding its memory `limit` gets killed with reason `OOMKilled`, visible in
`describe`'s "Last State" section. This workload needs about 150Mi; the current limit is far below
that. Raise both the request and the limit so the pod is not scheduled with less memory than it
uses.
