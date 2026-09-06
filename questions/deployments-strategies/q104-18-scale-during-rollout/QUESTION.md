# q104-18: Scale a Deployment up while a rollout is still stuck in progress

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-18-scale-during-rollout`

`setup.sh` already created a Deployment named `media-transcoder` in namespace
`q104-18-scale-during-rollout` with 4 replicas on image `nginx:1.24-alpine`, then started a
rollout to image `nginx:1.25-alpine` whose pods will never pass readiness (a probe pointed at a
path the image doesn't serve), so the rollout is currently stalled partway through.

Load on the service just spiked, so scale `media-transcoder` up to `8` replicas right now, without
waiting for the stuck rollout to resolve and without changing the image or the broken probe. The
Deployment controller proportionally scales both the old and new ReplicaSets to reach the new
total even mid-rollout - confirm `spec.replicas` reaches `8` and the combined pod count across all
of `media-transcoder`'s ReplicaSets reaches at least `8` (it may briefly sit a little above `8`,
up to the strategy's `maxSurge` headroom, since the new ReplicaSet can never actually finish
becoming available while its probe stays broken).

## Hint

Search kubernetes.io/docs for **"deployment proportional scaling"** - the Deployment concept
page's "Proportional Scaling" section explains how a rolling update Deployment distributes a
scale change across its old and new ReplicaSets simultaneously, even while a rollout is stuck.
