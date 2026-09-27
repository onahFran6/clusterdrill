# q105-29: Roll out a config change under an immutable ConfigMap

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-29-immutable-configmap-rollout-swap`

An immutable ConfigMap named `app-config-v1` (key `LOG_LEVEL=info`) already exists, plus a
Deployment named `worker` whose pod template mounts `app-config-v1` as a volume at `/etc/app`, in
namespace `q105-29-immutable-configmap-rollout-swap`. The Deployment is currently `Running`.

You need `worker`'s pods to report `LOG_LEVEL=debug` instead. Leave `app-config-v1` completely
untouched (still immutable, still `LOG_LEVEL=info`).

1. Create a new ConfigMap named `app-config-v2`, also marked immutable, with key `LOG_LEVEL=debug`.
2. Update the `worker` Deployment so its pods use `app-config-v2` at `/etc/app` instead.
3. Make sure every ready pod behind `worker` is recreated against the new config.

When you're done, every ready pod behind `worker` must have a file at `/etc/app/LOG_LEVEL`
containing `debug`, and `app-config-v1` must still exist, unmodified.

## Hint

Search kubernetes.io/docs for **"immutable ConfigMaps"** - the ConfigMaps concept page explains
that an immutable ConfigMap must be replaced by creating a new one and updating anything that
references it, rather than edited in place.
