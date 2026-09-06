# q101-40-create-configmap-from-env-file: Create a ConfigMap from an env file

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-40-create-configmap-from-env-file`

`setup.sh` already dropped a `KEY=VALUE`-per-line env file at
`~/practice-work/q101-40-create-configmap-from-env-file/service.env` containing:

```
RETRY_COUNT=3
TIMEOUT_SECONDS=30
```

In namespace `q101-40-create-configmap-from-env-file`, create a ConfigMap named `service-env` whose
data keys/values come from that file, using a single imperative
`kubectl create configmap --from-env-file` command (no manifest authored by hand). Unlike
`--from-file`, each line of the env file must become its own separate data key.

## Hint

Search kubernetes.io/docs for **"create configmaps from files"** - the ConfigMaps concept page's
"Define the key to use when creating a ConfigMap from a file" section also covers
`--from-env-file`, which turns each `KEY=VALUE` line into its own ConfigMap entry instead of one
whole-file key.
