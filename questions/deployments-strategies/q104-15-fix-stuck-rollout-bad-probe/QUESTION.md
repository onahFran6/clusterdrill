# q104-15: Fix a rollout stuck on a broken readiness probe

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-15-fix-stuck-rollout-bad-probe`

A Deployment named `checkout-api` already exists in namespace
`q104-15-fix-stuck-rollout-bad-probe` with 3 replicas. A rollout to image `nginx:1.25-alpine` is
stuck: the new pods never become Ready, so the update cannot complete.

Fix `checkout-api` so the rollout finishes: set the `readinessProbe`'s `httpGet.path` to `/`
(which `nginx:1.25-alpine` serves on port `80`), keep the image at `nginx:1.25-alpine`, and
confirm all 3 replicas become ready on the new image.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the pod
lifecycle docs show the `readinessProbe.httpGet` fields. A failing readiness check keeps a pod
out of a Deployment's available count, which stalls a rolling update. Compare the probe path on
the new pods with a path the image actually serves.
