# q105-38-downward-api-podinfo-env: Expose pod identity as environment variables via the Downward API

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-38-downward-api-podinfo-env`

`setup.sh` has not created any pod for you in namespace `q105-38-downward-api-podinfo-env` -
author the manifest yourself.

Create a Pod named `info-reporter`, image `busybox:1.36`, whose container runs `sleep 3600` and
has three environment variables sourced from the pod's own metadata via the Downward API
(`fieldRef`, not a ConfigMap or Secret):

- `MY_POD_NAME` - the pod's own name (`metadata.name`)
- `MY_POD_NAMESPACE` - the pod's own namespace (`metadata.namespace`)
- `MY_POD_IP` - the pod's own IP address (`status.podIP`)

The pod must reach `Running`.

## Hint

Search kubernetes.io/docs for **"downward api"** - the Expose Pod Information to Containers task
shows the "Using the Downward API through environment variables" section's `fieldRef` mappings
for `metadata.name`, `metadata.namespace`, and `status.podIP`.
