# q104-27: Set RollingUpdate surge and unavailability as percentages

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-27-rolling-update-both-percentages`

A Deployment named `catalog-svc` already exists in namespace
`q104-27-rolling-update-both-percentages` with 4 replicas of image `nginx:1.25-alpine`, using
the default `RollingUpdate` strategy.

Set `spec.strategy.rollingUpdate` so `maxSurge` is the string `"50%"` and `maxUnavailable` is
the string `"25%"` (percentages, not integers). Confirm the Deployment reaches 4 ready
replicas again.

## Hint

Search kubernetes.io/docs for **"Max Unavailable"** - the Deployment concept page's "Rolling
Update Deployment" section shows that `maxSurge`/`maxUnavailable` accept either an absolute
number or a percentage string like `"20%"`. Without explicit values both fields default to
`25%`.
