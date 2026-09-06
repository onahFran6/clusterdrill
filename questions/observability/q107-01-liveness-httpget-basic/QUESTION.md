# q107-01: Add an HTTP liveness probe to a running pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-01-liveness-httpget-basic`

`setup.sh` already created a pod named `web-front` (image `nginx:1.25-alpine`, listening on
container port `80`) in namespace `q107-01-liveness-httpget-basic`. The pod currently has no
liveness probe at all, so a hung worker process inside the container would never be restarted
automatically.

Edit the pod so it has a `livenessProbe` that:

- uses `httpGet` against path `/` on container port `80`
- sets `initialDelaySeconds` to `5`
- sets `periodSeconds` to `10`

Keep the pod named `web-front` and keep it running (you may delete and recreate it with the same
name to add the probe).

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the pod
lifecycle docs show the exact `livenessProbe.httpGet` YAML fields and their defaults.
