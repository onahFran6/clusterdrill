# q110-06: Record a release's live values

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-06-helm-get-values`

A Helm release named `cache-1` (chart `cache`) is installed in namespace
`q110-06-helm-get-values`. It was installed with a non-default `maxMemoryMb` - you don't know
the value in advance.

Find the actual `maxMemoryMb` value in use for `cache-1` (do not rely on the chart's default
`values.yaml` on disk), then create a ConfigMap named `inspected-values` in the same namespace
with a key `maxMemoryMb` set to that value as a string.

## Hint

Search kubernetes.io/docs for **"helm get values"** - the Helm get-values command reference
shows how to see exactly what values a release was actually installed or upgraded with, as
opposed to the chart's defaults.
