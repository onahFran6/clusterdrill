# q101-09: Create a ConfigMap from literal values

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-09-create-configmap-literal`

In namespace `q101-09-create-configmap-literal`, create a ConfigMap named `app-config` with
exactly these two keys:

- `LOG_LEVEL=info`
- `MAX_CONNECTIONS=100`

Use an imperative `kubectl` command with literal key/value flags - no YAML file authored by hand.

## Hint

Search kubernetes.io/docs for **"kubectl create configmap from-literal"** - the `kubectl create
configmap` reference shows how to set multiple key/value pairs without a data file.
