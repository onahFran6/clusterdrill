# q105-35: Fix a broken composed archive path

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-35-env-var-expansion-order-dependency`

Namespace `q105-35-env-var-expansion-order-dependency` has a ConfigMap named `region-config` with
key `REGION=eu-west-1`, and a running Pod named `path-builder` with one container `builder`
(image `busybox:1.36`). The container's `env` list is supposed to compose a final archive path
from four variables:

- `BASE_DIR` - a plain value, `/data`
- `REGION` - sourced from the `region-config` ConfigMap's `REGION` key via `configMapKeyRef`
- `ARCHIVE_PATH` - meant to expand to `$(BASE_DIR)/$(REGION)/archive`
- `FINAL_PATH` - meant to expand to `$(ARCHIVE_PATH)/current`

Right now `FINAL_PATH` does not resolve to a real path - the composed value is wrong.

Fix this by reordering the `builder` container's `env` list only - do not change any variable's
`value`, `valueFrom`, name, or the ConfigMap - so `FINAL_PATH` resolves to exactly
`/data/eu-west-1/archive/current`. `REGION` must keep coming from `region-config` via
`configMapKeyRef`. Recreate the Pod for the change to take effect.

## Hint

Search kubernetes.io/docs for **"dependent environment variables"** - the Define Dependent
Environment Variables task explains that `$(VAR_NAME)` only expands against variables already
defined earlier in the same container's `env` list, and that a reference to an undefined variable
is left unexpanded as a literal string.
