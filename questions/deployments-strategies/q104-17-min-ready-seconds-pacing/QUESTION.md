# q104-17: Slow a rollout down with minReadySeconds

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-17-min-ready-seconds-pacing`

`setup.sh` already created a Deployment named `event-bus` (image `nginx:1.24-alpine`, 3 replicas)
in namespace `q104-17-min-ready-seconds-pacing`, fully rolled out.

The team wants a safety buffer during rollouts: a newly-created pod passing its readiness probe
should not immediately count as "available" - it should have to stay ready for a sustained period
first, so a pod that flaps right after starting doesn't fool the rollout into proceeding too fast.
Set `event-bus`'s `minReadySeconds` to `10`, then trigger a rollout to image `nginx:1.25-alpine`
and confirm it completes successfully.

## Hint

Search kubernetes.io/docs for **"deployment minReadySeconds"** - the Deployment concept page
explains how this field delays when a pod counts as available, independent of its readiness
probe's own timing.
