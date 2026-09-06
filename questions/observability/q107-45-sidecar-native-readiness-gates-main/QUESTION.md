# q107-45: Diagnose a native sidecar's own readinessProbe blocking overall Pod readiness

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-45-sidecar-native-readiness-gates-main`

`setup.sh` already created a Pod named `metrics-app` with a native sidecar (an init container
`metrics-sidecar` with `restartPolicy: Always`) and a main container `metrics-app`. The main
container is healthy and Ready on its own, but the Pod as a whole never reaches Ready -
`metrics-sidecar`'s own `readinessProbe` targets port `9999`, which nothing in that container
listens on. Fix `metrics-sidecar`'s `readinessProbe` to target the port it actually serves on
(`80`), without changing `restartPolicy` or the main container, and confirm the whole Pod reaches
Ready.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the workloads concept page explains that
restartPolicy: Always init containers ("native sidecars") have their own readiness/liveness
probes, and overall Pod readiness requires every such sidecar to be Ready too, not just the main
application container.
