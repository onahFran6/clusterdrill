# q102-30: Let a Job complete while keeping a log-shipping sidecar

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-30-job-native-sidecar-completion-semantics`

The Job `log-shipping-job` in this namespace is supposed to run a short batch
task (container `digest`) alongside a log-shipping sidecar (container
`log-shipper`) that tails logs for as long as the Pod exists. The Job is stuck:
`kubectl get job log-shipping-job` shows `0/1` completions and never advances,
even though `digest` finishes and exits `0` every time.

Fix the Job so it reaches `status.succeeded: 1`, while still running both the
batch task and the log shipper:

- `log-shipper` must be a native sidecar: a single entry in
  `spec.template.spec.initContainers` named `log-shipper`, with
  `restartPolicy: Always` on that container. It should keep running
  `while true; do echo shipping logs; sleep 5; done` (image `busybox:1.36`).
- `digest` must remain the Job's only entry in `spec.template.spec.containers`,
  named `digest`, image `busybox:1.36`, still running a command that completes
  and exits `0`.
- The Pod's `spec.restartPolicy` must stay `Never` (required for a Job).
- The Job must be named `log-shipping-job` and must reach
  `status.succeeded == 1`.

A Job's `spec.template` is immutable once the Job exists - delete and recreate
the Job with the corrected spec.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the Workloads /
Pods page explains that an init container with `restartPolicy: Always`
becomes a native sidecar, and that kubelet terminates native sidecars
automatically once every regular container in the Pod has exited, which is
exactly what lets a Job with a sidecar reach `Complete`.
