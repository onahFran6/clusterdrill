# q104-27-rolling-update-both-percentages: Configure a RollingUpdate strategy using percentages, not fixed counts

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-27-rolling-update-both-percentages`

`setup.sh` already created a Deployment named `catalog-svc` (4 replicas, image `nginx:1.25-alpine`)
in namespace `q104-27-rolling-update-both-percentages`, using the default `RollingUpdate` strategy
with no explicit `maxSurge`/`maxUnavailable` (so both default to `25%`, expressed implicitly).

Explicitly set the Deployment's `spec.strategy.rollingUpdate` so `maxSurge` is the **string**
`"50%"` and `maxUnavailable` is the **string** `"25%"` (percentages, not integers), then confirm
the Deployment reaches 4 ready replicas again.

## Hint

Search kubernetes.io/docs for **"Max Unavailable"** - the Deployment concept page's "Rolling Update
Deployment" section shows that `maxSurge`/`maxUnavailable` accept either an absolute number or a
percentage string like `"20%"`.
