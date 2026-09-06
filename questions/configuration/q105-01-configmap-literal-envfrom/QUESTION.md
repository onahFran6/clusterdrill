# q105-01: Load an entire ConfigMap into a container's environment

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-01-configmap-literal-envfrom`

`setup.sh` already created a running pod named `catalog-app` (image `nginx:1.25-alpine`) in
namespace `q105-01-configmap-literal-envfrom`.

Create a ConfigMap named `catalog-env` with two literal keys:

- `CATALOG_MODE` = `readonly`
- `CATALOG_REGION` = `eu-west-1`

Then edit the pod's single container so that **every key in `catalog-env` becomes an environment
variable** inside the container, without listing the keys one by one. The pod will need to be
recreated for the change to take effect - that's expected.

## Hint

Search kubernetes.io/docs for **"envFrom configMapRef"** - the Configure a Pod to Use a ConfigMap
task shows how to bulk-import every key in a ConfigMap as environment variables in one stanza.
