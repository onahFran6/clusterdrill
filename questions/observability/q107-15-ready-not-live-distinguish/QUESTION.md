# q107-15: Fix a pod that's alive but never reports ready

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-15-ready-not-live-distinguish`

`setup.sh` already created a pod named `search-svc` (image `nginx:1.25-alpine`, listening on
container port `80`) in namespace `q107-15-ready-not-live-distinguish`. Run `kubectl get pod
search-svc -n q107-15-ready-not-live-distinguish` and you'll see the pod's `STATUS` is `Running`
with `0/1` in the `READY` column - it has not restarted, so the `livenessProbe` is passing and the
process is genuinely alive. It is simply never marked ready, which means a Service selecting this
pod would never route traffic to it.

The pod has two probes:

- `livenessProbe`: `httpGet` on path `/`, port `80` - correct, and the reason the pod hasn't
  restarted
- `readinessProbe`: `httpGet` on path `/does-not-exist`, port `80` - wrong, this path 404s on
  `nginx:1.25-alpine`, so readiness never succeeds

Fix only the `readinessProbe`'s `httpGet.path` to `/` so the pod becomes genuinely ready. Do not
change the `livenessProbe`.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the probes task
page contrasts what happens on liveness failure (container restarted) versus readiness failure
(pod stays running but is removed from Service endpoints) - the exact distinction this pod
demonstrates.
