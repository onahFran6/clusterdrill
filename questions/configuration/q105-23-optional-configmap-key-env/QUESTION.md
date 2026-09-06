# q105-23-optional-configmap-key-env: Reference an optional ConfigMap key that may not exist

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-23-optional-configmap-key-env`

`setup.sh` already created a ConfigMap named `app-flags` with only one key, `FEATURE_X=on`, plus a
pod named `flagreader` (image `nginx:1.25-alpine`) in namespace
`q105-23-optional-configmap-key-env`. The pod is currently failing to start with
`CreateContainerConfigError` because its container defines an environment variable `FEATURE_Y`
sourced via `valueFrom.configMapKeyRef` from a key that does not exist in `app-flags`.

Edit the pod so the `FEATURE_Y` environment variable's `configMapKeyRef` is marked `optional:
true`, so the container starts successfully even though that key is missing - the container
should simply not have a `FEATURE_Y` variable set at all. Do not change the `FEATURE_X` reference,
and do not add the missing key to the ConfigMap. The pod will need to be recreated for the change
to take effect, and it must end up Running and Ready.

## Hint

Search kubernetes.io/docs for **"configMapKeyRef optional"** - the Configure a Pod to Use a
ConfigMap task's "Define container environment variables using ConfigMap data" section shows how
marking a key reference optional lets a pod start even when that key doesn't exist.
