# q107-07: Diagnose and fix a pod stuck in CrashLoopBackOff

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-07-diagnose-crashloop-badcommand`

A pod named `batch-worker` (image `busybox:1.36`) already exists in namespace
`q107-07-diagnose-crashloop-badcommand`. The pod is stuck in `CrashLoopBackOff`.

Find out why the container keeps exiting, then fix the pod so it stays running:

- the pod is still named `batch-worker` in the same namespace
- the container still uses image `busybox:1.36`
- the container's command keeps the process running indefinitely instead of exiting immediately
- the pod reaches and stays in the `Running` phase with its container `Ready`

## Hint

Search kubernetes.io/docs for **"kubectl describe pod"** - the kubectl reference page's `describe`
output includes the container's last termination reason and exit code, which is the fastest way to
tell "crashed on startup" apart from "probe killed it" or "OOMKilled." `kubectl logs` on
`batch-worker` shows the same failure. A command that sleeps, instead of exiting, is one way to
keep the process running.
