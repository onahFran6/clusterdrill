# q107-49: Diagnose two crash-looping Pods with genuinely different root causes

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-49-diagnose-two-simultaneous-crashloops-different-causes`

`setup.sh` already created two Pods in this namespace, `worker-a` and `worker-b`, both stuck in
`CrashLoopBackOff` - **for two different reasons**. Do not assume they share one root cause.
Diagnose each independently and fix only what's actually broken in each:

- `worker-a` (image `busybox:1.36`) - fix its command so the container can actually start.
- `worker-b` (image `polinux/stress`, running `stress --vm 1 --vm-bytes 150M --vm-hang 1`) - fix
  its memory limit so `stress`'s real memory usage fits, without changing its command/args.

Both must reach `Running`/Ready.

## Hint

Search kubernetes.io/docs for **"determine the reason for pod failure"** - the debugging page
covers reading `kubectl describe pod`'s events and `lastState.terminated.reason` to tell apart
different failure causes (a bad executable name vs. `OOMKilled`) instead of guessing.
