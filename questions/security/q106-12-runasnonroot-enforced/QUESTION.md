# q106-12: Enforce non-root execution and make the pod actually run

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-12-runasnonroot-enforced`

Create a pod named `hardened-app` in namespace `q106-12-runasnonroot-enforced` that:

- runs image `nginxinc/nginx-unprivileged:1.25-alpine`
- sets pod-level `securityContext.runAsNonRoot` to `true`
- reaches the `Running` phase

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or container"** - the
task page explains what `runAsNonRoot` verifies at container start. It only rejects root; it
does not choose a UID. If the image's default user is root, the pod fails to start (often
`CreateContainerConfigError`). Use an image that already defaults to a non-root user.
