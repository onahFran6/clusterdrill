# q107-06: Loosen an overly strict liveness probe so occasional slow responses don't kill the pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-06-tune-probe-timing-flaky`

`setup.sh` already created a pod named `report-generator` (image `nginx:1.25-alpine`, listening on
container port `80`) in namespace `q107-06-tune-probe-timing-flaky`, with a `livenessProbe`
configured as:

- `httpGet` on path `/`, port `80`
- `periodSeconds: 2`
- `failureThreshold: 1`

This app occasionally takes a couple of seconds longer to answer under load, and with
`failureThreshold: 1` a single slow response is treated as a permanent failure and the container
gets restarted - a false alarm, not a real crash.

Edit the pod's `livenessProbe` so it tolerates occasional slowness without weakening it to the
point of never catching a real hang:

- keep `httpGet` on path `/`, port `80`
- set `periodSeconds` to `10`
- set `failureThreshold` to `3`
- set `timeoutSeconds` to `5`

## Hint

Search kubernetes.io/docs for **"configure probes"** - the probes task page's "Probe configuration"
table lists `periodSeconds`, `failureThreshold`, and `timeoutSeconds` and how they interact to
decide when a probe result counts as a real failure.
