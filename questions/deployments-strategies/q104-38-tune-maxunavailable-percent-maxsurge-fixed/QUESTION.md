# q104-38: Mix percentage maxUnavailable with fixed-count maxSurge

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-38-tune-maxunavailable-percent-maxsurge-fixed`

A Deployment named `catalog-api` (image `nginx:1.24-alpine`, 5 replicas) already exists in
namespace `q104-38-tune-maxunavailable-percent-maxsurge-fixed`, using the default rolling update
settings.

Set `catalog-api`'s `spec.strategy.rollingUpdate` so `maxUnavailable` is the string `"20%"` and
`maxSurge` is the integer `3` - without changing the replica count or the image. Confirm the
Deployment settles back at 5 ready replicas.

## Hint

Search kubernetes.io/docs for **"Max Unavailable"** - the Deployment concept page's "Rolling
Update Deployment" section shows that `maxSurge` and `maxUnavailable` are each independently
either an absolute number or a percentage string - one field's format doesn't constrain the other.
