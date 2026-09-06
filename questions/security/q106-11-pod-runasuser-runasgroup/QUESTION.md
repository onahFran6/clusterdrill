# q106-11: Run a pod as a specific non-root UID and GID

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-11-pod-runasuser-runasgroup`

In namespace `q106-11-pod-runasuser-runasgroup`, create a pod named `worker` running image
`busybox:1.36` (command `sleep 3600`) whose pod-level `securityContext` sets:

- `runAsUser` to `1000`
- `runAsGroup` to `3000`

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or container"** - the
task page shows the `runAsUser`/`runAsGroup` fields at the pod spec level with a full example.
