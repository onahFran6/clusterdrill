# q105-29-immutable-configmap-rollout-swap: Roll out a config change under an immutable ConfigMap by swapping names

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-29-immutable-configmap-rollout-swap`

`setup.sh` already created an immutable ConfigMap named `app-config-v1` (key `LOG_LEVEL=info`) and
a Deployment named `worker` whose pod template mounts `app-config-v1` as a volume at `/etc/app`,
in namespace `q105-29-immutable-configmap-rollout-swap`. The Deployment is currently `Running`.

You need `worker`'s pods to report `LOG_LEVEL=debug` instead - but `app-config-v1` is marked
`immutable: true`, so its `data` cannot be patched or edited in place. Leave `app-config-v1`
completely untouched (still immutable, still `LOG_LEVEL=info`).

Instead:

1. Create a new ConfigMap named `app-config-v2`, also marked immutable, with key
   `LOG_LEVEL=debug`.
2. Update the `worker` Deployment's volume so its pod template references `app-config-v2`
   instead of `app-config-v1`.
3. Trigger a rollout so every pod is recreated against the new mount.

When you're done, every ready pod behind `worker` must have a file at `/etc/app/LOG_LEVEL`
containing `debug`, and `app-config-v1` must still exist, unmodified.

## Hint

Search kubernetes.io/docs for **"immutable ConfigMaps"** - the ConfigMaps concept page explains
that an immutable ConfigMap must be replaced by creating a new one and updating anything that
references it, rather than edited in place.
