# q107-02: Add an HTTP readiness probe so a pod stops receiving traffic when unhealthy

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-02-readiness-httpget-basic`

A pod named `catalog-api` (image `nginx:1.25-alpine`, listening on container port `80`) already
exists in namespace `q107-02-readiness-httpget-basic`. It has no readiness probe.

Edit the pod so it has a `readinessProbe` that:

- uses `httpGet` against path `/` on container port `80`
- sets `periodSeconds` to `5`
- sets `failureThreshold` to `3`

Keep the pod named `catalog-api` and keep it running (you may delete and recreate it with the same
name to add the probe).

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the same page
that documents `livenessProbe` also covers `readinessProbe`'s identical field shape and how it
differs in effect (removed from Service endpoints, not restarted). A running container with no
readiness probe gives Kubernetes no signal for whether the app is ready to serve traffic.
