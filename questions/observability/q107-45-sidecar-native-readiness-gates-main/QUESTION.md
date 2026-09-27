# q107-45: Diagnose a native sidecar's own readinessProbe blocking overall Pod readiness

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-45-sidecar-native-readiness-gates-main`

A Pod named `metrics-app` already exists with a native sidecar (init container `metrics-sidecar`
with `restartPolicy: Always`) and a main container `metrics-app`. The main container is healthy,
but the Pod as a whole never reaches Ready.

Set `metrics-sidecar`'s `readinessProbe` to port `80`. Do not change `restartPolicy` or the main
container. Confirm the whole Pod reaches Ready.

## Hint

Search kubernetes.io/docs for **"sidecar containers"** - the workloads concept page explains that
restartPolicy: Always init containers ("native sidecars") have their own readiness/liveness
probes, and overall Pod readiness requires every such sidecar to be Ready too, not just the main
application container. `metrics-sidecar`'s probe currently targets port `9999`, which nothing in
that container listens on. The container serves on port `80`.
