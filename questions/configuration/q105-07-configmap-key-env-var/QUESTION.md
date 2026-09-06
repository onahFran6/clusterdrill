# q105-07: Inject a single ConfigMap key as one environment variable

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-07-configmap-key-env-var`

`setup.sh` already created a ConfigMap named `feature-flags` with keys `NEW_CHECKOUT=enabled`
and `DARK_MODE=disabled`, plus a running pod named `storefront` (image `nginx:1.25-alpine`), in
namespace `q105-07-configmap-key-env-var`.

Edit the pod so its container gets **exactly one** new environment variable, `CHECKOUT_FLAG`,
whose value is sourced from the `NEW_CHECKOUT` key of `feature-flags` - do not import the whole
ConfigMap, and do not add an environment variable for `DARK_MODE`. The pod will need to be
recreated for the change to take effect.

## Hint

Search kubernetes.io/docs for **"configMapKeyRef"** - the Configure a Pod to Use a ConfigMap task
shows how to map a single ConfigMap key to one named environment variable via
`valueFrom.configMapKeyRef`.
