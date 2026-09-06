# q101-09: Create a ConfigMap from literal values

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-09-create-configmap-literal`

In namespace `q101-09-create-configmap-literal`, create a ConfigMap named `app-config` with the
following imperative `kubectl` command, containing exactly these two keys:

- `LOG_LEVEL=info`
- `MAX_CONNECTIONS=100`

No YAML file authored by hand - use literal key/value flags.

## Hint

Search kubernetes.io/docs for **"kubectl create configmap from-literal"** - the `kubectl create
configmap` reference shows how to set multiple key/value pairs without a data file.
