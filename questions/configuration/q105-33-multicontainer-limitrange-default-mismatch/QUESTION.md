# q105-33: Fix a two-container pod's memory requests

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-33-multicontainer-limitrange-default-mismatch`

A `LimitRange` named `container-mem-defaults` in namespace
`q105-33-multicontainer-limitrange-default-mismatch` applies to `Container`-kind objects with
default memory limit `128Mi` and default memory request `64Mi`.

A manifest at `~/worker.yaml` defines a two-container Pod named `worker`:

- container `collector` declares no `resources` field at all.
- container `shipper` declares `resources.limits.memory: 256Mi` but no `resources.requests`.

The team's capacity plan assumes every container in this Pod requests exactly `64Mi` of memory.
Apply `~/worker.yaml` as-is first and inspect the resulting `resources` on both containers.

Then fix `~/worker.yaml` so that, once applied:

- `collector` keeps no explicit `resources` field (it should inherit the `LimitRange` defaults:
  memory limit `128Mi` / memory request `64Mi`).
- `shipper` keeps its `256Mi` memory limit but explicitly requests `64Mi` of memory.
- Do not modify the `container-mem-defaults` LimitRange - solve this in the Pod manifest.

Delete and recreate the Pod with the corrected manifest so the fix takes effect, and confirm
`worker` ends up `Running` with both containers showing the values above.

## Hint

Search kubernetes.io/docs for **"LimitRange constraints"** - the LimitRange concept page's
"Constraints on Resource Ranges" section explains how a container's declared limit is validated
and defaulted, and how an unset request resolves differently depending on whether the container
has its own explicit limit or falls back entirely to the `LimitRange`'s `defaultRequest`.
