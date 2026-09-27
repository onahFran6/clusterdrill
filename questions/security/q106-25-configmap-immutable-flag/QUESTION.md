# q106-25-configmap-immutable-flag: Mark a ConfigMap immutable after creation

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-25-configmap-immutable-flag`

Namespace `q106-25-configmap-immutable-flag` already has a ConfigMap named `app-config` with two
keys: `LOG_LEVEL` (`info`) and `FEATURE_FLAG` (`enabled`). The ConfigMap is mutable.

Set `app-config`'s `immutable` field to `true`. Do not change either existing key or value.

## Hint

Search kubernetes.io/docs for **"ConfigMap immutable"** - the ConfigMaps concept page has a
dedicated "Immutable ConfigMaps" section explaining the field and how to set it. Once a ConfigMap
is immutable, Kubernetes rejects further edits to `data`, `binaryData`, and `immutable`, so set
the flag only after `data` is already correct.
