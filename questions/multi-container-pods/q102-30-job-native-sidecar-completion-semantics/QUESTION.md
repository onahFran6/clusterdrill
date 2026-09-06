# q102-30: Job stuck Active because its sidecar is not a native sidecar

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-30-job-native-sidecar-completion-semantics`

The Job `log-shipping-job` in this namespace is supposed to run a short batch
task (container `digest`) alongside a log-shipping sidecar (container
`log-shipper`) that tails logs for as long as the Pod exists. The Job is
stuck: `kubectl get job log-shipping-job` shows `0/1` completions and never
advances, even though `digest` finishes and exits `0` every time.

The bug: `log-shipper` was added to `spec.template.spec.containers` as an
ordinary second container instead of being wired up as a **native sidecar**.
A Job's Pod only reaches phase `Succeeded` once *every* container in it has
exited - so with `log-shipper` looping forever as a regular container, the
Pod (and therefore the Job) can never complete.

Fix the Job so it reaches `status.succeeded: 1`, while still running both
the batch task and the log shipper:

- `log-shipper` must be defined as a **native sidecar**: a single entry in
  `spec.template.spec.initContainers` named `log-shipper`, with
  `restartPolicy: Always` set on that container. It should keep running
  `while true; do echo shipping logs; sleep 5; done` (image `busybox:1.36`).
- `digest` must remain the Job's only entry in `spec.template.spec.containers`,
  named `digest`, image `busybox:1.36`, still running a command that
  completes and exits `0`.
- The Pod's `spec.restartPolicy` must stay `Never` (required for a Job).
- The Job must be named `log-shipping-job` and must reach
  `status.succeeded == 1`.

A Job's `spec.template` is immutable once the Job exists, so an in-place
`kubectl edit`/`kubectl patch` of the running Job's pod template will be
rejected - you will need to delete and recreate the Job with the corrected
spec.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the Workloads /
Pods page explains that an init container with `restartPolicy: Always`
becomes a native sidecar, and that kubelet terminates native sidecars
automatically once every regular container in the Pod has exited, which is
exactly what lets a Job with a sidecar reach `Complete`.
