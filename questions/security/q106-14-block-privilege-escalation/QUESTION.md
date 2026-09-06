# q106-14: Block a container from gaining more privileges than its parent process

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-14-block-privilege-escalation`

`setup.sh` already created a running pod named `legacy-worker` (image `busybox:1.36`, command
`sleep 3600`) in namespace `q106-14-block-privilege-escalation`. It currently allows its process
to gain more privileges than its parent, which a security scan flagged.

Edit the pod (recreating it under the same name if needed) so the container's
`securityContext.allowPrivilegeEscalation` is set to `false`, and confirm the pod reaches
`Running` afterward.

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or container"** - the
task page documents `allowPrivilegeEscalation` and notes it's implied `false` whenever
`privileged: true` is not set and `capabilities` are dropped, but should still be set explicitly
here.
