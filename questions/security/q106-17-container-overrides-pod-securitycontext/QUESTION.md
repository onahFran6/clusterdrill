# q106-17: Override the pod's securityContext for one container only

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-17-container-overrides-pod-securitycontext`

A pod runs two containers that share most of the same hardening, but one of them needs a
different UID than the pod-wide default because of how its image is built.

Create a pod named `mixed-uid` in namespace `q106-17-container-overrides-pod-securitycontext`
with:

- pod-level `securityContext.runAsUser` set to `1000` (the default for the whole pod)
- container `standard` (image `busybox:1.36`, command `sleep 3600`) with **no** container-level
  `securityContext` - it should inherit UID `1000` from the pod
- container `special` (image `busybox:1.36`, command `sleep 3600`) with its own container-level
  `securityContext.runAsUser` set to `2000`, overriding the pod default for that container only

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or container"** - the
task page explains that container-level `securityContext` fields take precedence over pod-level
ones when both are set for the same field.
