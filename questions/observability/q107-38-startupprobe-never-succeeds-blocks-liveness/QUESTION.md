# q107-38: Fix a startupProbe that's blocking a healthy container from ever being Ready

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-38-startupprobe-never-succeeds-blocks-liveness`

`setup.sh` already created a running Pod named `slow-starter` (image `nginx:1.25-alpine`) with a
`startupProbe` checking `path: /this-path-does-not-exist` on port 80. nginx is actually up and
serving fine on `/` - but until `startupProbe` succeeds, kubelet never even begins running
`livenessProbe`/`readinessProbe`, so the Pod is stuck "not started" forever even though nothing
is actually crashing. Fix `startupProbe` to check a path that will actually succeed, without
changing `livenessProbe` or `readinessProbe`, and confirm the Pod reaches Ready.

## Hint

Search kubernetes.io/docs for **"define startup probes"** - the probes task page explains that
while a Pod's `startupProbe` is defined and hasn't yet succeeded, all other probes are disabled,
so a startupProbe that can never pass silently blocks liveness and readiness checking entirely.
