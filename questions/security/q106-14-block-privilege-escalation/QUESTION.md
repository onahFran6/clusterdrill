# q106-14: Block a container from gaining more privileges than its parent process

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-14-block-privilege-escalation`

A running pod named `legacy-worker` (image `busybox:1.36`, command `sleep 3600`) already exists
in namespace `q106-14-block-privilege-escalation`. Its process can gain more privileges than its
parent.

Edit the pod (recreating it under the same name if needed) so the container's
`securityContext.allowPrivilegeEscalation` is `false`, and confirm the pod reaches `Running`.

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or container"** - the
task page documents `allowPrivilegeEscalation`. Set it explicitly on the container even when
other settings would imply the same restriction. Some security-context fields apply only when
the container is created, so recreate the pod under the same name if an edit is rejected.
