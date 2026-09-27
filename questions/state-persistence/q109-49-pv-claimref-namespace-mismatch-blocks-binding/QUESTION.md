# q109-49-pv-claimref-namespace-mismatch-blocks-binding: Fix a PV pre-bound to a claim in the wrong namespace

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-49-pv-claimref-namespace-mismatch-blocks-binding`

A PersistentVolume named `preassigned-pv` already exists (capacity `100Mi`, access mode
`ReadWriteOnce`, storage class name `""`, `hostPath`-backed at `/mnt/q109-49-preassigned`).
Its `spec.claimRef` reserves it for a claim named `preassigned-claim`, but that claim does
not bind.

A PersistentVolumeClaim named `preassigned-claim` already exists in namespace
`q109-49-pv-claimref-namespace-mismatch-blocks-binding` and stays `Pending`.

Recreate `preassigned-pv` so `claimRef.namespace` is
`q109-49-pv-claimref-namespace-mismatch-blocks-binding` and `claimRef.name` stays
`preassigned-claim`. Keep capacity, access mode, storage class name, and `hostPath` the same
so the claim binds.

## Hint

Search kubernetes.io/docs for **"persistentvolume claimRef"** - the Persistent Volumes API
reference's `claimRef` field is an `ObjectReference` that names both the claim and its
namespace. A PV pre-bound to a claim reference that does not match a real claim's name and
namespace never binds, including a claim with the right name in a different namespace.
`claimRef` cannot be patched in place. The current `claimRef.namespace` is
`q109-49-wrong-namespace`.
