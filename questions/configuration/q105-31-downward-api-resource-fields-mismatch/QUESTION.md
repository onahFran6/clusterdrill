# q105-31: Fix a sidecar that never becomes Ready

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-31-downward-api-resource-fields-mismatch`

A Pod named `sidecar-metrics` has two containers in namespace
`q105-31-downward-api-resource-fields-mismatch`: `main` (memory limit `200Mi`) and `metrics`
(memory limit `64Mi`). The `metrics` container exposes a memory limit to itself as the environment
variable `CONTAINER_MEM_LIMIT` via the Downward API, writes that value to `/tmp/limit` at startup,
and its readiness probe checks that `/tmp/limit` equals the `metrics` container's own memory
limit. The Pod is not Ready.

Fix the Pod so that:

- Neither container's memory limits change: `main` keeps `200Mi`, `metrics` keeps `64Mi`.
- `metrics`' `CONTAINER_MEM_LIMIT` resolves to the `metrics` container's own `64Mi` limit (as
  reported through the Downward API).
- Pod `sidecar-metrics` reaches `2/2` Ready.

Do not change either container's `resources.limits`.

## Hint

Search kubernetes.io/docs for **"resourcefieldref"** and separately for **"downward api"** - the
"Expose Pod Information to Containers" tasks explain that a `resourceFieldRef` env var must name
the container whose resource value it should expose, which defaults to the current container only
when `containerName` is omitted entirely.
