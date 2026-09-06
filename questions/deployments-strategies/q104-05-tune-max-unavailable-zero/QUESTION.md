# q104-05: Tune a Deployment for zero-downtime rollouts

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-05-tune-max-unavailable-zero`

`setup.sh` already created a Deployment named `api-gateway` (image `nginx:1.24-alpine`, 4 replicas)
in namespace `q104-05-tune-max-unavailable-zero`, using the default rolling update settings.

The on-call team wants future rollouts of `api-gateway` to never drop below its full serving
capacity. Change its update strategy so that during any rollout `maxUnavailable` is `0` and
`maxSurge` is `2` (up to 2 extra pods may exist temporarily, but capacity may never dip below 4
ready pods). Apply the change without changing the replica count or the image.

## Hint

Search kubernetes.io/docs for **"deployment rolling update maxSurge maxUnavailable"** - the
Deployment concept page explains how the two `rollingUpdate` fields interact to control rollout
speed versus available capacity.
