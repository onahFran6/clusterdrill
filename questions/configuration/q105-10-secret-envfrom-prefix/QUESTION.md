# q105-10: Bulk-import a Secret's keys with a common env var prefix

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-10-secret-envfrom-prefix`

`setup.sh` already created a generic Secret named `payment-creds` with two keys, `API_KEY` and
`API_SECRET`, plus a running pod named `payment-worker` (image `nginx:1.25-alpine`), in namespace
`q105-10-secret-envfrom-prefix`.

Edit the pod so its container bulk-imports every key from `payment-creds` as environment
variables, each one prefixed with `PAY_` - so the container ends up with environment variables
named `PAY_API_KEY` and `PAY_API_SECRET` (not the bare `API_KEY` / `API_SECRET` names). The pod
will need to be recreated for the change to take effect.

## Hint

Search kubernetes.io/docs for **"envFrom prefix"** - the EnvFromSource API reference documents
the optional `prefix` field used when bulk-importing a Secret or ConfigMap's keys as environment
variables.
