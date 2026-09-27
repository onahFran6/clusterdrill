# q110-28-crd-finalizer-stuck-deletion: Unblock a CRD instance stuck deleting due to a custom finalizer

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-28-crd-finalizer-stuck-deletion`

A CRD named `archives.storage.clusterdrill.io` (kind `Archive`, group
`storage.clusterdrill.io/v1`, namespaced) is registered. An Archive named `cold-store-1` in
this namespace is stuck in `Terminating` after a delete was issued - it never finishes removing.

Diagnose why deletion cannot complete, then unblock it so `cold-store-1` actually disappears.
Do not delete the CRD itself.

## Hint

Search kubernetes.io/docs for **"using finalizers to control deletion"** - an object with a
non-empty `metadata.finalizers` list stays in `Terminating` until every finalizer is removed.
Inspect `cold-store-1` for a custom finalizer and clear it (for example with `kubectl patch`)
without deleting the CRD.
