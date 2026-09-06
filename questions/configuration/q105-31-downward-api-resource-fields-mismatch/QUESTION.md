# q105-31-downward-api-resource-fields-mismatch: Fix a Downward API env var exposing the wrong container's resource limit

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-31-downward-api-resource-fields-mismatch`

`setup.sh` already created, in namespace `q105-31-downward-api-resource-fields-mismatch`, a Pod
named `sidecar-metrics` with two containers: `main` (memory limit `200Mi`) and `metrics` (memory
limit `64Mi`). The `metrics` container exposes its own memory limit to itself through the
Downward API as the environment variable `CONTAINER_MEM_LIMIT`, using a `resourceFieldRef`. At
startup it writes that variable's value to `/tmp/limit`, and its readiness probe checks that
`/tmp/limit` equals the `metrics` container's own actual memory limit. Right now the Pod is not
Ready.

Inspect the Pod's manifest and find the mistake in how `CONTAINER_MEM_LIMIT` is wired. Fix it so
that:

- Neither container's actual resource limits change: `main` keeps its `200Mi` memory limit and
  `metrics` keeps its `64Mi` memory limit.
- The `metrics` container's `CONTAINER_MEM_LIMIT` environment variable resolves to the `metrics`
  container's own `64Mi` limit (as reported through the Downward API), not `main`'s.
- Pod `sidecar-metrics` reaches `2/2` Ready.

Fix this by editing the `metrics` container's `CONTAINER_MEM_LIMIT` env entry so its
`resourceFieldRef.containerName` points at `metrics` instead of `main` - do not change either
container's `resources.limits`.

## Hint

Search kubernetes.io/docs for **"resourcefieldref"** and separately for **"downward api"** - the
"Expose Pod Information to Containers" tasks explain that a `resourceFieldRef` env var must name
the container whose resource value it should expose, which defaults to the current container only
when `containerName` is omitted entirely.
