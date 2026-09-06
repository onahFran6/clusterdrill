# q104-36-scale-via-patch-merge: Scale a Deployment with a JSON merge patch

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-36-scale-via-patch-merge`

`setup.sh` already created a Deployment named `session-store` (container name `session-store`,
image `memcached:1.6-alpine`, 3 replicas) in namespace `q104-36-scale-via-patch-merge`, and it is
already fully rolled out with all 3 replicas Ready.

Scale `session-store` up to exactly `6` replicas using `kubectl patch` with a JSON merge patch
(`--type=merge`) - do not use `kubectl scale` and do not use `kubectl edit`. Wait until all 6
replicas report Ready.

## Hint

Search kubernetes.io/docs for **"kubectl patch"** - the `kubectl patch` command reference shows
how a `--type=merge` patch with a JSON body can update a single field like `spec.replicas` without
touching the rest of the object.
