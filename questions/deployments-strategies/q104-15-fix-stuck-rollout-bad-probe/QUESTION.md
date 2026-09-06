# q104-15: Fix a rollout stuck on a broken readiness probe

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-15-fix-stuck-rollout-bad-probe`

`setup.sh` already created a Deployment named `checkout-api` in namespace
`q104-15-fix-stuck-rollout-bad-probe` with 3 replicas. A rollout to image `nginx:1.25-alpine` is
currently stuck: the new pods' `readinessProbe` checks an HTTP path (`/does-not-exist`) that this
image never serves, so they fail readiness forever and the rollout can't progress past the first
replaced pod.

Fix `checkout-api` so the rollout actually completes: correct the `readinessProbe`'s `httpGet.path`
to `/` (which `nginx:1.25-alpine` does serve on port `80`), keep the image at
`nginx:1.25-alpine`, and confirm all 3 replicas become ready on the new image.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the pod
lifecycle docs show the `readinessProbe.httpGet` fields and how a failing readiness check keeps a
pod out of a Deployment's available count indefinitely.
