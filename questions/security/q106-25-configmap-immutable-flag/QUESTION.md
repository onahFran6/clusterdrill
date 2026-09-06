# q106-25-configmap-immutable-flag: Mark a ConfigMap immutable after creation

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-25-configmap-immutable-flag`

`setup.sh` already created, in namespace `q106-25-configmap-immutable-flag`, a ConfigMap named
`app-config` with two keys: `LOG_LEVEL` (value `info`) and `FEATURE_FLAG` (value `enabled`). The
ConfigMap is currently mutable - it has no `immutable` field set.

Mark `app-config` as immutable by setting its `.immutable` field to `true`, without changing
either existing key or value. Once a ConfigMap is marked immutable, Kubernetes prevents any
further edits to its `data`, `binaryData`, or `immutable` fields, so patching `immutable` is a
one-way operation - do it only after you're sure `data` is already correct.

## Hint

Search kubernetes.io/docs for **"ConfigMap immutable"** - the ConfigMaps concept page has a
dedicated "Immutable ConfigMaps" section explaining the field and how to set it.
