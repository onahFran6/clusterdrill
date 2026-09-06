# q105-44-limitrange-ephemeral-storage: Bound container ephemeral storage with a LimitRange

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-44-limitrange-ephemeral-storage`

Namespace `q105-44-limitrange-ephemeral-storage` already exists, with no `LimitRange` or pods yet.

Create a `LimitRange` named `storage-limits` that bounds each container's `ephemeral-storage`:

- `default` (the limit auto-filled when a container doesn't set one): `500Mi`
- `defaultRequest` (the request auto-filled when a container doesn't set one): `100Mi`
- `min`: `50Mi`
- `max`: `1Gi`

Then create a pod named `scratch-worker` (image `busybox:1.36`, running `sleep 3600`) whose
container sets **no** `ephemeral-storage` request or limit of its own at all - relying entirely on
`storage-limits` to fill in the `100Mi` request and `500Mi` limit automatically. The pod must
reach `Running`.

## Hint

Search kubernetes.io/docs for **"limitrange"** - the LimitRange concept page's example manifests
show `default`/`defaultRequest`/`min`/`max` for `ephemeral-storage`, the same fields normally used
for `cpu`/`memory`.
