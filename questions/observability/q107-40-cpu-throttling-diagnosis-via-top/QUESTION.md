# q107-40: Diagnose and fix a CPU limit causing severe throttling

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-40-cpu-throttling-diagnosis-via-top`

A running Pod named `number-cruncher` (image `busybox:1.36`) already exists. It runs a tight
busy-loop with `resources.limits.cpu: 10m`. It is not crash-looping.

Using `kubectl top`, confirm what is holding the container back, then set its CPU limit to at
least `100m`. Do not change the image or command.

## Hint

Search kubernetes.io/docs for **"assign CPU resource"** - the compute resources task page explains
that a container's CPU usage is hard-capped at its `limits.cpu` value (throttled, not killed), and
`kubectl top pod` is the tool for spotting usage pinned at that ceiling. This Pod is not
OOMKilled; the loop cannot run faster than the 10m cap.
