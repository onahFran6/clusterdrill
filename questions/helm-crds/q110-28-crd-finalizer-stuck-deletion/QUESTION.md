# q110-28-crd-finalizer-stuck-deletion: Unblock a CRD instance stuck deleting due to a custom finalizer

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-28-crd-finalizer-stuck-deletion`

`setup.sh` registered a CRD named `archives.storage.clusterdrill.io` (kind `Archive`, group
`storage.clusterdrill.io/v1`, namespaced) and created an instance named `cold-store-1` in
namespace `q110-28-crd-finalizer-stuck-deletion` with `spec.sizeGb: 50` and a custom finalizer
`storage.clusterdrill.io/cleanup` in `metadata.finalizers`. A delete was then issued against
`cold-store-1`, so it already has a non-null `metadata.deletionTimestamp` and shows as
`Terminating` - but there is no controller running that ever removes the finalizer, so it will
stay stuck in `Terminating` forever.

Diagnose why `cold-store-1` cannot finish deleting, then unblock it by removing its finalizer so
the object actually finishes deleting and disappears. Do **not** delete the CRD
`archives.storage.clusterdrill.io` itself - only unblock and remove the `cold-store-1` instance.

## Hint

Search kubernetes.io/docs for **"using finalizers to control deletion"** - the Owners and
Finalizers section explains that an object with a non-empty `metadata.finalizers` list will stay
in `Terminating` until every finalizer is removed, and shows how a stuck object's finalizers can
be cleared with `kubectl patch`.
