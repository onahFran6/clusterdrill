# q101-19: Create a pod with CPU/memory requests and limits imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-19-run-pod-resource-limits`

In namespace `q101-19-run-pod-resource-limits`, create a pod named `sized-app` running image
`nginx:1.25-alpine` whose single container has these resource settings:

- requests: `cpu=100m`, `memory=64Mi`
- limits: `cpu=250m`, `memory=128Mi`

Use a single imperative `kubectl run` command (an inline `--overrides` JSON patch is the
imperative way to set fields `kubectl run` has no dedicated flag for) - no manifest authored by
hand.

## Hint

Search kubernetes.io/docs for **"kubectl run overrides"** - the `kubectl run` reference documents
the `--overrides` flag for merging an inline JSON patch into the generated pod spec, and the
"Assign Memory Resources to Containers" task page shows the requests/limits schema shape to put in
that patch.
