# q106-46: Grant a non-root container permission to bind a privileged port

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-46-capabilities-net-bind-service-port80`

A Pod named `privileged-port-listener` already exists. It runs as non-root (`runAsUser: 1000`)
and crash-loops while trying to listen on TCP port 80.

Fix container `listener` so the Pod becomes Ready. It must still run as UID `1000`, still drop
every other capability (`drop: ["ALL"]`), and add exactly one capability.

## Hint

Search kubernetes.io/docs for **"set capabilities for a container"** - the security context task
page explains that binding TCP/UDP ports below 1024 as a non-root user requires the
`NET_BIND_SERVICE` Linux capability, added via `securityContext.capabilities.add`. Add that one
capability and nothing more.
