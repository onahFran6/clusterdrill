# q105-19: Override one bulk-imported ConfigMap value without changing the ConfigMap

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-19-configmap-override-individual-env`

A ConfigMap named `service-defaults` already exists with two keys, `TIMEOUT_SECONDS=30` and
`RETRY_COUNT=3`, plus a running Pod named `notifier` (image `nginx:1.25-alpine`) whose container
already bulk-imports every key from `service-defaults` as environment variables, in namespace
`q105-19-configmap-override-individual-env`.

Without editing the ConfigMap itself, change the pod so the container's final environment has
`TIMEOUT_SECONDS=90` while `RETRY_COUNT` still comes from the ConfigMap unchanged (`3`). The pod
will need to be recreated for the change to take effect.

Verify with `kubectl exec notifier -- printenv TIMEOUT_SECONDS RETRY_COUNT` - it should show
`90` and `3`.

## Hint

Search kubernetes.io/docs for **"define an environment variable for a container"** - the Define
Environment Variables for a Container task's notes explain the precedence order between `env` and
`envFrom` when the same variable name appears in both.
