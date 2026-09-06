# q106-15: Trim Linux capabilities to the minimum a container needs

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-15-capabilities-add-drop`

A container needs to bind to a low-numbered network port without running as root, but should
otherwise have no more kernel capabilities than absolutely necessary.

Create a pod named `net-tool` in namespace `q106-15-capabilities-add-drop` with a single
container (image `busybox:1.36`, command `sleep 3600`) whose `securityContext.capabilities`:

- drops `ALL` capabilities
- then adds back only `NET_BIND_SERVICE`

## Hint

Search kubernetes.io/docs for **"add capabilities to a container"** - the security-context task
page shows the exact `capabilities.drop`/`capabilities.add` list shape, including the "drop ALL,
add back only what's needed" pattern.
