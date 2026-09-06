# q105-11: Set CPU and memory requests and limits on a container

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-11-resource-requests-limits`

Create a pod named `batch-worker` in namespace `q105-11-resource-requests-limits` running image
`nginx:1.25-alpine`, with its single container configured with:

- CPU request: `100m`
- CPU limit: `250m`
- Memory request: `128Mi`
- Memory limit: `256Mi`

`setup.sh` has not created this pod for you - author the manifest (or imperative command plus
patch) yourself.

## Hint

Search kubernetes.io/docs for **"resource requests and limits"** - the Assign Memory/CPU
Resources to Containers and Pods tasks show the `resources.requests`/`resources.limits` container
fields and their units (`m` for millicpu, `Mi` for mebibytes).
