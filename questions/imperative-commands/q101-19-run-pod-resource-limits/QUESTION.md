# q101-19: Create a Pod with CPU and memory requests and limits

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-19-run-pod-resource-limits`

In namespace `q101-19-run-pod-resource-limits`, create a Pod named `sized-app` running image
`nginx:1.25-alpine` whose single container has:

- requests: `cpu=100m`, `memory=64Mi`
- limits: `cpu=250m`, `memory=128Mi`

Use a single imperative `kubectl run` command - no manifest authored by hand.

## Hint

Search kubernetes.io/docs for **"kubectl run overrides"** - the `kubectl run` reference documents
the `--overrides` flag for merging an inline JSON patch into the generated pod spec, and the
"Assign Memory Resources to Containers" task page shows the requests/limits schema shape to put in
that patch.
