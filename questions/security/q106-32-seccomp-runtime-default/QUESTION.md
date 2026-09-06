# q106-32: Opt a container in to the RuntimeDefault seccomp profile

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-32-seccomp-runtime-default`

A pod named `worker` is already running in namespace `q106-32-seccomp-runtime-default`. Its
container `worker` (image `busybox:1.36`, command `sleep 3600`) has no `securityContext` at all,
so it runs "unconfined" - whatever the container runtime's default seccomp posture happens to be,
rather than an explicit, auditable choice.

Edit the pod (recreating it if you need to - some `securityContext` fields cannot be changed on a
running pod) so that container `worker`'s `securityContext.seccompProfile.type` is set to
`RuntimeDefault`. Leave the image and command unchanged. When you're done, `worker` must still be
`Running` and `Ready`.

## Hint

Search kubernetes.io/docs for **"restrict a container's syscalls with seccomp"** - the seccomp
tutorial shows the exact `securityContext.seccompProfile` shape, including the `type:
RuntimeDefault` value.
