# q104-29: Restore a Deployment stuck at zero available replicas

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-29-diagnose-and-fix-cascading-strategy-misconfig`

A Deployment named `payments-web` already exists in namespace
`q104-29-diagnose-and-fix-cascading-strategy-misconfig` with 2 replicas of image
`nginx:1.25-alpine`. A recent RollingUpdate left `availableReplicas` at `0` - no pods are
Ready.

Restore service:

- Fix the `readinessProbe` so new pods can become Ready (`httpGet.path` must be `/`).
- Set the RollingUpdate strategy to `maxUnavailable: 0` and `maxSurge: 1` (integers, not
  percentages).
- Confirm `availableReplicas` returns to `2`.

## Hint

Search kubernetes.io/docs for **"Max Unavailable"** and **"readinessProbe"** - the Deployment
concept page's "Rolling Update Deployment" section explains why a high `maxUnavailable`
combined with a failing readiness check can take every replica down at once, and how safer
integer surge/unavailability values limit that risk.
