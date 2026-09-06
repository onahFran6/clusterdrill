# q106-46: Grant a non-root container permission to bind a privileged port

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-46-capabilities-net-bind-service-port80`

`setup.sh` already created a Pod named `privileged-port-listener` that runs as non-root
(`runAsUser: 1000`) and tries to listen on TCP port 80 - a privileged port that non-root processes
cannot bind on Linux without an extra capability, so it is crash-looping. Fix `listener`'s container
so it can bind port 80 while still running as UID `1000` and still dropping every other capability
(`drop: ["ALL"]`) - add exactly the one capability needed, nothing more, and reach Ready.

## Hint

Search kubernetes.io/docs for **"set capabilities for a container"** - the security context task
page explains that binding TCP/UDP ports below 1024 as a non-root user requires the
`NET_BIND_SERVICE` Linux capability, added via `securityContext.capabilities.add`.
