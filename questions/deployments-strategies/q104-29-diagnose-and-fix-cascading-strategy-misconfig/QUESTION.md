# q104-29-diagnose-and-fix-cascading-strategy-misconfig: Recover from a total-outage rollout caused by a reckless strategy plus a broken probe

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-29-diagnose-and-fix-cascading-strategy-misconfig`

`setup.sh` already created a Deployment named `payments-web` (2 replicas, image `nginx:1.25-alpine`)
in namespace `q104-29-diagnose-and-fix-cascading-strategy-misconfig`. It was healthy, then someone
made two changes at once:

1. Set `spec.strategy.rollingUpdate` to `maxUnavailable: "100%"`, `maxSurge: "0%"` - meaning a
   rollout tears down **all** old pods before any replacement needs to be ready.
2. Broke the pod template's `readinessProbe` so it checks `httpGet.path: /definitely-missing`
   instead of `/` - a path that always 404s on the stock nginx image.

The combination is a full outage: the rollout killed every old (working) pod immediately (since
`maxUnavailable` is 100%), and none of the new pods can ever pass the broken readiness check, so
`availableReplicas` is stuck at `0`.

Fix both problems:

- Correct the `readinessProbe`'s `httpGet.path` back to `/`.
- Change the strategy to `maxUnavailable: 0` and `maxSurge: 1` (as integers, not percentages) so a
  future bad rollout can never repeat this same all-at-once failure mode.
- Confirm the Deployment reaches `availableReplicas: 2` again.

## Hint

Search kubernetes.io/docs for **"Max Unavailable"** and **"readinessProbe"** - the Deployment
concept page's "Rolling Update Deployment" section explains why `maxUnavailable: 100%` combined
with a broken readiness check is a guaranteed total outage, and how safer integer values prevent it.
