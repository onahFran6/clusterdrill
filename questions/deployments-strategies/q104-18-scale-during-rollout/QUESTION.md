# q104-18: Scale a Deployment up while a rollout is still stuck in progress

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-18-scale-during-rollout`

A Deployment named `media-transcoder` already exists in namespace
`q104-18-scale-during-rollout` with 4 replicas. A rollout to image `nginx:1.25-alpine` is stuck
partway through (the new pods never become Ready).

Scale `media-transcoder` up to `8` replicas now, without waiting for the rollout to finish and
without changing the image or the readiness probe. Confirm `spec.replicas` is `8` and the
combined pod count across all of `media-transcoder`'s ReplicaSets is at least `8` (it may sit a
little above `8` while the new ReplicaSet cannot finish becoming available).

## Hint

Search kubernetes.io/docs for **"deployment proportional scaling"** - the Deployment concept
page's "Proportional Scaling" section explains how a rolling-update Deployment distributes a
scale change across its old and new ReplicaSets even while a rollout is stuck. Default
`maxSurge` headroom can leave the combined ReplicaSet total temporarily above the new replica
count.
