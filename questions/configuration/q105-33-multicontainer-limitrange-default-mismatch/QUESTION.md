# q105-33: Fix a two-container pod's LimitRange default-request mismatch

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-33-multicontainer-limitrange-default-mismatch`

`setup.sh` already created a `LimitRange` named `container-mem-defaults` in namespace
`q105-33-multicontainer-limitrange-default-mismatch` that applies to `Container`-kind objects:

- default memory **limit**: `128Mi`
- default memory **request**: `64Mi`

A manifest at `~/worker.yaml` in your terminal's working directory defines a two-container pod
named `worker`:

- container `collector` declares no `resources` field at all.
- container `shipper` declares an explicit `resources.limits.memory: 256Mi` (it periodically
  compresses batches of shipped logs and needs the extra headroom) but no `resources.requests`
  at all.

The team's capacity plan assumes **every container in this pod requests exactly `64Mi` of memory
as its baseline**, matching the namespace's own default request. `collector` already satisfies
that once it inherits the `LimitRange`'s defaults - but `shipper` will not: because `shipper` sets
an explicit memory **limit**, Kubernetes derives its unset request from *that limit*, not from the
`LimitRange`'s `defaultRequest`, once a limit is present on the container. Applying `~/worker.yaml`
as-is would silently request `256Mi` for `shipper` - four times the intended baseline.

Apply the manifest as-is first and inspect the resulting `resources` on both containers to confirm
this.

Then fix `~/worker.yaml` so that, once applied:

- `collector` keeps no explicit `resources` field, inheriting the `LimitRange`'s defaults (memory
  limit `128Mi` / memory request `64Mi`).
- `shipper` keeps its `256Mi` memory limit unchanged (the burst headroom is a real requirement -
  do not lower it) but explicitly requests `64Mi` of memory, matching the capacity plan's
  baseline.
- Do not modify the `container-mem-defaults` `LimitRange` itself - solve this in the pod's
  manifest, not the namespace policy.

Delete and recreate the pod with the corrected manifest so the fix takes effect, and confirm
`worker` ends up `Running` with both containers showing the values above.

## Hint

Search kubernetes.io/docs for **"LimitRange constraints"** - the LimitRange concept page's
"Constraints on Resource Ranges" section explains how a container's declared limit is validated
and defaulted, and how an unset request resolves differently depending on whether the container
has its own explicit limit or falls back entirely to the `LimitRange`'s `defaultRequest`.
