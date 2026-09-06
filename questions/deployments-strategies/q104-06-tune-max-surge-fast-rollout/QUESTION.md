# q104-06: Speed up a rollout with a larger maxSurge

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-06-tune-max-surge-fast-rollout`

`setup.sh` already created a Deployment named `image-resizer` (image `nginx:1.24-alpine`, 6
replicas) in namespace `q104-06-tune-max-surge-fast-rollout`, using the default rolling update
settings (25% maxSurge, 25% maxUnavailable).

The team wants rollouts of `image-resizer` to replace as many pods in parallel as possible.
Change its strategy so `maxSurge` is `100%` and `maxUnavailable` is `0` (all 6 replacement pods
may come up at once, alongside the originals, and capacity may never drop). Then trigger a
rollout by updating the image to `nginx:1.25-alpine` and confirm it completes successfully.

## Hint

Search kubernetes.io/docs for **"deployment rolling update maxSurge maxUnavailable"** - the
Deployment concept page's rolling update section documents percentage values for both fields, not
just absolute pod counts.
