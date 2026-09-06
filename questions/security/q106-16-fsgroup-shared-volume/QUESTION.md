# q106-16: Share a volume's group ownership across containers

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-16-fsgroup-shared-volume`

Two containers in the same pod need to read and write the same files in a shared `emptyDir`
volume, even though each container runs as a different non-root UID. The cleanest fix is a shared
supplementary group applied to the volume, not matching UIDs.

Create a pod named `shared-writer` in namespace `q106-16-fsgroup-shared-volume` with:

- pod-level `securityContext.fsGroup` set to `2000`
- an `emptyDir` volume named `data` mounted at `/data` in both containers:
  - container `writer` (image `busybox:1.36`, command `sleep 3600`)
  - container `reader` (image `busybox:1.36`, command `sleep 3600`)

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or container"** - the
"Configure volume permission and ownership change policy for Pods" section covers `fsGroup` and
how it applies to mounted volumes.
