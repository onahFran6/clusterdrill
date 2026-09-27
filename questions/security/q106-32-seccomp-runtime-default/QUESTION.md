# q106-32: Opt a container in to the RuntimeDefault seccomp profile

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-32-seccomp-runtime-default`

A pod named `worker` is already running in namespace `q106-32-seccomp-runtime-default`. Its
container `worker` (image `busybox:1.36`, command `sleep 3600`) has no `securityContext`.

Edit the pod so container `worker`'s `securityContext.seccompProfile.type` is `RuntimeDefault`.
Leave the image and command unchanged. When you are done, `worker` must still be `Running` and
`Ready`. Recreate the pod if the field cannot be changed in place.

## Hint

Search kubernetes.io/docs for **"restrict a container's syscalls with seccomp"** - the seccomp
tutorial shows the exact `securityContext.seccompProfile` shape, including `type: RuntimeDefault`.
With no profile set, the container stays Unconfined rather than an explicit, auditable profile.
Some `securityContext` fields cannot be changed on a running pod.
