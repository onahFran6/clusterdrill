# q111-16: A health check that blocks the rollout

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-16-readiness-probe-blocks-rollout`

Team Flora added a readiness check to `menu` (seeded, 3 replicas), and since then its rollout
never finishes: 3 old pods are still `1/1`, and 1 new pod is stuck `0/1`. They don't want to roll
back - the readiness check must stay, but it should check path `/` instead.

- Before fixing, work out (or check) how many `menu` pods are currently Ready and serving.
- Identify why the new pods never became Ready - check the stuck pod's own events.
- Fix forward so the rollout completes with all 3 pods Ready, keeping the readiness check.

## Hint

Search kubernetes.io/docs for **"Configure Liveness, Readiness and Startup Probes"**. Work out
the defaults for 3 replicas first: how many pods can be unavailable, and how many extra pods may
exist during a rollout? That predicts exactly what you'll see before you even look. The new
pod's own events say precisely why its readiness probe is failing.
