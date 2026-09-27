# q107-15: Fix a pod that's alive but never reports ready

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-15-ready-not-live-distinguish`

A pod named `search-svc` (image `nginx:1.25-alpine`, listening on container port `80`) already
exists in namespace `q107-15-ready-not-live-distinguish`. It is `Running` with `READY` at `0/1`,
and it has not been restarted.

Fix the `readinessProbe` so its `httpGet.path` is `/` and the pod becomes Ready. Do not change
the `livenessProbe`.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the probes task
page contrasts what happens on liveness failure (container restarted) versus readiness failure
(pod stays running but is removed from Service endpoints). The liveness probe already requests
`/` and is passing. The readiness probe requests `/does-not-exist`, which 404s on
`nginx:1.25-alpine`, so the pod never becomes Ready and a Service selecting it would send no
traffic.
