# q107-03: Add a startup probe to protect a slow-initializing app from its own liveness probe

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-03-startup-probe-slow-init`

`setup.sh` already created a pod named `legacy-monolith` (image `nginx:1.25-alpine`, listening on
container port `80`) in namespace `q107-03-startup-probe-slow-init`. It already has a
`livenessProbe` (`httpGet` on `/`, `periodSeconds: 5`, `failureThreshold: 1`) tuned for a healthy
running app. In production this app is known to take up to 90 seconds to finish initializing
before it can answer any HTTP request at all - with only the `livenessProbe` in place, Kubernetes
would kill the container for "failing" before it ever finishes starting.

Add a `startupProbe` to the `legacy-monolith` container that:

- uses `httpGet` against path `/` on container port `80`
- sets `periodSeconds` to `10`
- sets `failureThreshold` to `9` (so the startup window covers roughly 90 seconds before the
  regular `livenessProbe` takes over)

Do not remove or change the existing `livenessProbe`.

## Hint

Search kubernetes.io/docs for **"startupProbe"** - the probes task page explains how a
`startupProbe` disables liveness and readiness checks until it succeeds, protecting slow-starting
containers from being killed prematurely.
