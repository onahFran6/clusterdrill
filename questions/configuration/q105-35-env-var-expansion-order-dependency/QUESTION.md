# q105-35-env-var-expansion-order-dependency: Fix a broken $(VAR) expansion chain caused by env list ordering

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-35-env-var-expansion-order-dependency`

`setup.sh` already created, in namespace `q105-35-env-var-expansion-order-dependency`, a ConfigMap
named `region-config` with key `REGION=eu-west-1`, and a running Pod named `path-builder` with one
container `builder` (image `busybox:1.36`) whose `env` list is supposed to compose a final archive
path out of three pieces:

- `BASE_DIR` - a plain value, `/data`
- `REGION` - sourced from the `region-config` ConfigMap's `REGION` key via `configMapKeyRef`
- `ARCHIVE_PATH` - a plain value meant to expand to `$(BASE_DIR)/$(REGION)/archive`
- `FINAL_PATH` - a plain value meant to expand to `$(ARCHIVE_PATH)/current`

Right now the container's env list defines `ARCHIVE_PATH` **before** `BASE_DIR` and `REGION`, so
`$(BASE_DIR)` and `$(REGION)` are not yet defined at the point `ARCHIVE_PATH` is evaluated -
Kubernetes only expands a `$(VAR_NAME)` reference for a variable defined **earlier** in the same
container's `env` list; anything referencing a not-yet-defined variable is left as a literal
string instead. Because `ARCHIVE_PATH` itself ends up as the literal text
`$(BASE_DIR)/$(REGION)/archive`, `FINAL_PATH` (which does come after `ARCHIVE_PATH` and expands
`$(ARCHIVE_PATH)` correctly) inherits that broken literal and ends up as
`$(BASE_DIR)/$(REGION)/archive/current` instead of a real path.

Fix this by reordering the `builder` container's `env` list - and **only** reordering it, do not
change any variable's `value`, `valueFrom`, name, or the ConfigMap - so that `BASE_DIR` and
`REGION` are both defined before `ARCHIVE_PATH`, and `ARCHIVE_PATH` is defined before
`FINAL_PATH`. `REGION` must keep coming from the `region-config` ConfigMap via `configMapKeyRef`
(do not replace it with a hardcoded value). The pod will need to be recreated for the change to
take effect. Once fixed, the container's `FINAL_PATH` environment variable must resolve to exactly
`/data/eu-west-1/archive/current`.

## Hint

Search kubernetes.io/docs for **"dependent environment variables"** - the Define Dependent
Environment Variables task explains that `$(VAR_NAME)` only expands against variables already
defined earlier in the same container's `env` list, and that a reference to an undefined variable
is left unexpanded as a literal string.
