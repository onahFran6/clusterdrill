# q105-23: Start a Pod that references a ConfigMap key that may not exist

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-23-optional-configmap-key-env`

A ConfigMap named `app-flags` already exists with only one key, `FEATURE_X=on`, plus a Pod named
`flagreader` (image `nginx:1.25-alpine`) in namespace `q105-23-optional-configmap-key-env`. The
pod is failing to start with `CreateContainerConfigError` - its container expects an environment
variable `FEATURE_Y` from `app-flags`, but that key is not in the ConfigMap.

Fix the pod so it reaches Running and Ready even though `FEATURE_Y` is missing from `app-flags`.
Do not change the `FEATURE_X` reference, and do not add the missing key to the ConfigMap. The
container should simply not have a `FEATURE_Y` variable set. Recreating the pod is fine.

## Hint

Search kubernetes.io/docs for **"configMapKeyRef optional"** - the Configure a Pod to Use a
ConfigMap task's "Define container environment variables using ConfigMap data" section shows how
marking a key reference optional lets a pod start even when that key doesn't exist.
