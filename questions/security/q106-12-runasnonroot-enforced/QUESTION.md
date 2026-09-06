# q106-12: Enforce non-root execution and make the pod actually run

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-12-runasnonroot-enforced`

Create a pod named `hardened-app` in namespace `q106-12-runasnonroot-enforced` that:

- runs image `nginxinc/nginx-unprivileged:1.25-alpine` (an image built to run as a non-root user)
- sets pod-level `securityContext.runAsNonRoot` to `true`
- reaches the `Running` phase (not stuck in `CreateContainerConfigError` or similar)

`runAsNonRoot: true` only enforces that the container **doesn't** run as root - it does not by
itself pick a UID, so the image itself must already default to a non-root user or the pod will
fail to start.

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or container"** - the
task page explains what `runAsNonRoot` verifies at container start and what happens when the
image's default user is root.
