# q109-49-pv-claimref-namespace-mismatch-blocks-binding: Fix a PV pre-bound to a claim in the wrong namespace

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-49-pv-claimref-namespace-mismatch-blocks-binding`

`setup.sh` already created a PersistentVolume named `preassigned-pv` (capacity `100Mi`, access
mode `ReadWriteOnce`, storage class name `""`, `hostPath`-backed at
`/mnt/q109-49-preassigned`) with `spec.claimRef` pre-set to reserve it for a claim named
`preassigned-claim` - but the `claimRef.namespace` was typed as `q109-49-wrong-namespace`
instead of this task's real namespace. `setup.sh` also created a PersistentVolumeClaim named
`preassigned-claim` in the **correct** namespace,
`q109-49-pv-claimref-namespace-mismatch-blocks-binding`.

A PV's `claimRef` pre-binds it to one specific claim by name **and** namespace - since the
namespace in `preassigned-pv`'s `claimRef` doesn't match where the real claim actually lives,
the two can never bind to each other, and `preassigned-claim` sits `Pending` forever even though
a PV that looks like an exact match for it already exists.

`claimRef` cannot be patched on an existing PersistentVolume - delete and recreate
`preassigned-pv` with `claimRef.namespace` corrected to
`q109-49-pv-claimref-namespace-mismatch-blocks-binding`, keeping `claimRef.name`
(`preassigned-claim`) and every other field the same, so it binds.

## Hint

Search kubernetes.io/docs for **"persistentvolume claimRef"** - the Persistent Volumes API
reference's `claimRef` field is an `ObjectReference` that names both the claim and its
namespace; a PV pre-bound to a claim reference that doesn't exactly match a real claim's
identity (name **and** namespace) never binds to anything, including a claim with the right name
in the wrong namespace.
