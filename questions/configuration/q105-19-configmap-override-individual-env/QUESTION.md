# q105-19: Override one bulk-imported ConfigMap value without changing the ConfigMap

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-19-configmap-override-individual-env`

`setup.sh` already created a ConfigMap named `service-defaults` with two keys, `TIMEOUT_SECONDS=30`
and `RETRY_COUNT=3`, plus a running pod named `notifier` (image `nginx:1.25-alpine`) whose
container already bulk-imports `service-defaults` via `envFrom`, in namespace
`q105-19-configmap-override-individual-env`.

Without editing the ConfigMap itself, edit the pod's container so that the final environment the
container sees has `TIMEOUT_SECONDS=90` while `RETRY_COUNT` still comes from the ConfigMap
unchanged (`3`). Do this by adding an individual `env` entry for `TIMEOUT_SECONDS` **after** the
existing `envFrom` in the container spec - a container's explicitly listed `env` entries take
precedence over same-named variables pulled in via `envFrom`. The pod will need to be recreated
for the change to take effect.

## Hint

Search kubernetes.io/docs for **"define an environment variable for a container"** - the Define
Environment Variables for a Container task's notes explain the precedence order between `env` and
`envFrom` when the same variable name appears in both.
