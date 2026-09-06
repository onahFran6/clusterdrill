# q106-13: Lock the container's root filesystem to read-only

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-13-readonly-root-filesystem`

Create a pod named `immutable-app` in namespace `q106-13-readonly-root-filesystem` that:

- runs image `busybox:1.36` with command `sleep 3600`
- sets the container's `securityContext.readOnlyRootFilesystem` to `true`
- mounts an `emptyDir` volume at `/scratch` so the container still has one writable path despite
  the read-only root filesystem

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or container"** - the
task page's read-only filesystem example shows pairing `readOnlyRootFilesystem` with a mounted
`emptyDir` for any path the container still needs to write to.
