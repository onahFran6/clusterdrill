# q107-38: Fix a startupProbe that's blocking a healthy container from ever being Ready

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-38-startupprobe-never-succeeds-blocks-liveness`

A Pod named `slow-starter` (image `nginx:1.25-alpine`) already exists. nginx is serving on `/`,
but the Pod never becomes Ready because its `startupProbe` does not succeed.

Fix `startupProbe` so it checks a path that succeeds. Do not change `livenessProbe` or
`readinessProbe`. Confirm the Pod reaches Ready.

## Hint

Search kubernetes.io/docs for **"define startup probes"** - the probes task page explains that
while a Pod's `startupProbe` is defined and hasn't yet succeeded, all other probes are disabled,
so a startupProbe that can never pass silently blocks liveness and readiness checking entirely.
This one checks `path: /this-path-does-not-exist` on port 80. `/` is the path nginx actually
serves.
