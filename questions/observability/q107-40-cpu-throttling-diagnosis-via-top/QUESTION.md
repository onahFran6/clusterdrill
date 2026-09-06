# q107-40: Diagnose and fix a CPU limit causing severe throttling

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-40-cpu-throttling-diagnosis-via-top`

`setup.sh` already created a running Pod named `number-cruncher` (image `busybox:1.36`) running a
tight busy-loop, with `resources.limits.cpu: 10m`. It's not crashing or OOMKilled - it's severely
CPU-throttled: `kubectl top pod` shows usage flat-lined at the limit no matter how much work the
loop tries to do. Diagnose this using `kubectl top`, then raise the container's CPU limit to at
least `100m` so it can actually run, without changing the image or command.

## Hint

Search kubernetes.io/docs for **"assign CPU resource"** - the compute resources task page explains
that a container's CPU usage is hard-capped at its `limits.cpu` value (throttled, not killed), and
`kubectl top pod` is the tool for spotting usage pinned at that ceiling.
