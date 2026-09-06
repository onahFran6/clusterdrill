# q104-38-tune-maxunavailable-percent-maxsurge-fixed: Mix a percentage maxUnavailable with a fixed-count maxSurge

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-38-tune-maxunavailable-percent-maxsurge-fixed`

`setup.sh` already created a Deployment named `catalog-api` (image `nginx:1.24-alpine`, 5
replicas) in namespace `q104-38-tune-maxunavailable-percent-maxsurge-fixed`, using the default
rolling update settings.

`maxSurge` and `maxUnavailable` don't have to use the same value type. Set `catalog-api`'s
`spec.strategy.rollingUpdate` so `maxUnavailable` is the **string** `"20%"` (a percentage) and
`maxSurge` is the **integer** `3` (a fixed pod count) - without changing the replica count or the
image. Confirm the Deployment settles back at 5 ready replicas.

## Hint

Search kubernetes.io/docs for **"Max Unavailable"** - the Deployment concept page's "Rolling
Update Deployment" section shows that `maxSurge` and `maxUnavailable` are each independently
either an absolute number or a percentage string - one field's format doesn't constrain the other.
