# q107-06: Loosen an overly strict liveness probe so occasional slow responses don't kill the pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-06-tune-probe-timing-flaky`

A pod named `report-generator` (image `nginx:1.25-alpine`, listening on container port `80`)
already exists in namespace `q107-06-tune-probe-timing-flaky`, with a `livenessProbe` configured
as:

- `httpGet` on path `/`, port `80`
- `periodSeconds: 2`
- `failureThreshold: 1`

Occasional slow responses are restarting the container. Edit the pod's `livenessProbe` so it
tolerates that slowness without weakening it to the point of never catching a real hang:

- keep `httpGet` on path `/`, port `80`
- set `periodSeconds` to `10`
- set `failureThreshold` to `3`
- set `timeoutSeconds` to `5`

## Hint

Search kubernetes.io/docs for **"configure probes"** - the probes task page's "Probe configuration"
table lists `periodSeconds`, `failureThreshold`, and `timeoutSeconds` and how they interact to
decide when a probe result counts as a real failure. With `failureThreshold: 1`, a single slow
response is treated as a permanent failure and the container is restarted.
