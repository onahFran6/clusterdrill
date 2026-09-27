# q102-24: Stop a worker that keeps exiting under OnFailure

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-24-restartpolicy-onfailure-sidecar-crashloop`

A Pod named `stream-proc` already exists in this namespace with
`spec.restartPolicy: OnFailure` and two containers:

- An init container named `log-tailer` (image `busybox:1.36`) with
  `restartPolicy: Always` on the container itself - a native sidecar that runs
  `tail -F /data/app.log` for the lifetime of the Pod.
- A main container named `worker` (image `busybox:1.36`) that is supposed to
  loop forever, appending a line to `/data/app.log` every 10 seconds.

Instead, `worker` keeps exiting with a non-zero status roughly every 10
seconds. Because the Pod's `restartPolicy` is `OnFailure`, the kubelet keeps
restarting it, and `log-tailer`'s restart count also climbs.

Inspect the Pod's events and container statuses, then fix `worker` so it keeps
running (looping forever, or exiting `0` cleanly each iteration) without
changing the container names, images, or the Pod's `restartPolicy`. You cannot
patch `command` in place on a running Pod, so delete and recreate `stream-proc`
with the corrected script. Confirm the Pod stabilizes on `Running`, that
`log-tailer` shows up as a `Running` init container with `restartPolicy: Always`,
and that `worker`'s restart count stops climbing.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the Workloads /
Pods page's "Sidecar containers" section covers native sidecars started via
`initContainers[].restartPolicy: Always`, and how the Pod-level
`restartPolicy` (`Always` / `OnFailure` / `Never`) governs how the kubelet
reacts when a regular container in the Pod exits. Check `worker`'s command
for an early exit.
