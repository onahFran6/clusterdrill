# q110-06: Inspect a release's user-supplied values

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-06-helm-get-values`

`setup.sh` installed a Helm release named `cache-1` (chart `cache`) into namespace
`q110-06-helm-get-values`. It was installed with a `--set` override for `maxMemoryMb` that is
not the chart's default - you don't know the value in advance.

Find the actual `maxMemoryMb` value `cache-1` was installed with (without just reading the
chart's default `values.yaml` on disk), then record it by creating a ConfigMap named
`inspected-values` in the same namespace with a key `maxMemoryMb` set to that value as a string.

## Hint

Search kubernetes.io/docs for **"helm get values"** - the Helm get-values command reference
shows how to see exactly what values a release was actually installed or upgraded with, as
opposed to the chart's defaults.

