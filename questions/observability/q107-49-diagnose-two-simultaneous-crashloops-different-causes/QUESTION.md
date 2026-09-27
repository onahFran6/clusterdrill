# q107-49: Diagnose two crash-looping Pods with genuinely different root causes

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-49-diagnose-two-simultaneous-crashloops-different-causes`

Two Pods already exist in this namespace, `worker-a` (image `busybox:1.36`) and `worker-b`
(image `polinux/stress`). Both are stuck in `CrashLoopBackOff`, for different reasons.

Diagnose each one and fix only what is broken. Both must reach `Running` and Ready. Do not change
either image. Do not change `worker-b`'s command or arguments.

## Hint

Search kubernetes.io/docs for **"determine the reason for pod failure"** - the debugging page
covers reading `kubectl describe pod`'s events and `lastState.terminated.reason` to tell apart
different failure causes (a bad executable name vs. `OOMKilled`) instead of guessing. `worker-a`
needs a command the image can actually run. `worker-b` runs
`stress --vm 1 --vm-bytes 150M --vm-hang 1`; raise its memory limit so that usage fits (at least
200Mi) and leave those arguments unchanged.
