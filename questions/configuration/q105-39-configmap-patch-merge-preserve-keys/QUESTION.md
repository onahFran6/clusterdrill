# q105-39: Add a key to an existing ConfigMap without losing the others

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-39-configmap-patch-merge-preserve-keys`

A ConfigMap named `app-settings` already exists in namespace
`q105-39-configmap-patch-merge-preserve-keys` with two keys: `LOG_LEVEL=info` and `TIMEOUT=30`.

Add a third key, `MAX_RETRIES=5`, to `app-settings` **without changing or removing**
`LOG_LEVEL` or `TIMEOUT`. Use a merge-style update (for example `kubectl patch --type=merge`,
`kubectl edit`, or `kubectl apply` against a manifest that includes all three keys) - do not
delete and recreate the ConfigMap from a manifest that only contains `MAX_RETRIES`, since that
would wipe the two existing keys.

## Hint

Search kubernetes.io/docs for **"kubectl patch"** - the kubectl Reference Docs' `patch` command
page explains the default strategic merge behavior: a JSON merge patch only touches the fields
you name and leaves every other existing field in the object untouched.
