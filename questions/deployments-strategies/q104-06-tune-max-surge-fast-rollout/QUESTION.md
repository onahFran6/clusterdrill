# q104-06: Speed up a Deployment rollout without dropping capacity

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-06-tune-max-surge-fast-rollout`

A Deployment named `image-resizer` (image `nginx:1.24-alpine`, 6 replicas) already exists
in namespace `q104-06-tune-max-surge-fast-rollout`, using the default rolling update settings.

The team wants rollouts of `image-resizer` to replace as many pods in parallel as possible
without dropping capacity. Change its strategy so `maxSurge` is `100%` and `maxUnavailable` is
`0`. Then trigger a rollout by updating the image to `nginx:1.25-alpine` and confirm it
completes successfully.

## Hint

Search kubernetes.io/docs for **"deployment rolling update maxSurge maxUnavailable"** - the
Deployment concept page's rolling update section documents percentage values for both fields, not
just absolute pod counts. `maxSurge: 100%` lets all replacement pods come up at once alongside
the originals while `maxUnavailable: 0` keeps capacity from dropping.
