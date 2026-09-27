# q102-10: Native sidecar via init container restartPolicy

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-10-native-sidecar-restart-always`

Create a Pod named `native-sidecar-app` with two containers:

- An init container named `sidecar-log-agent` (image `busybox:1.36`) that runs
  `sh -c "while true; do echo agent running; sleep 5; done"` and has
  `restartPolicy: Always` set on the container itself (a native sidecar). It
  starts before the main container, stays running for the Pod's lifetime, and
  does not block the Pod from being considered started.
- A main container named `main` (image `nginx:1.27-alpine`).

The Pod must end up with exactly one entry in `spec.initContainers`, named
`sidecar-log-agent`, with `restartPolicy` set to exactly `Always`.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the Workloads /
Pods page's "Sidecar containers" section shows how to set `restartPolicy:
Always` on an init container to make it a native sidecar.
