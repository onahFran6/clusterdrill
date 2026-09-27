# q107-03: Add a startup probe to protect a slow-initializing app from its own liveness probe

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-03-startup-probe-slow-init`

A pod named `legacy-monolith` (image `nginx:1.25-alpine`, listening on container port `80`) already
exists in namespace `q107-03-startup-probe-slow-init`. It already has a `livenessProbe` (`httpGet`
on `/`, `periodSeconds: 5`, `failureThreshold: 1`).

Add a `startupProbe` to the `legacy-monolith` container that:

- uses `httpGet` against path `/` on container port `80`
- sets `periodSeconds` to `10`
- sets `failureThreshold` to `9`

Do not remove or change the existing `livenessProbe`.

## Hint

Search kubernetes.io/docs for **"startupProbe"** - the probes task page explains how a
`startupProbe` disables liveness and readiness checks until it succeeds, protecting slow-starting
containers from being killed prematurely. `periodSeconds: 10` with `failureThreshold: 9` covers
about 90 seconds before the existing liveness probe takes over. This app can take that long before
it answers any HTTP request; with only the current liveness probe, Kubernetes would kill it for
failing before startup finished.
