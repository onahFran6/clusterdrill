# q109-34-fix-pvc-storageclassname-typo: Fix a PVC stuck Pending on a typo'd StorageClass name

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-34-fix-pvc-storageclassname-typo`

`setup.sh` already created a PersistentVolumeClaim named `reports-data` in namespace
`q109-34-fix-pvc-storageclassname-typo`, requesting `100Mi` with access mode
`ReadWriteOnce` and `storageClassName: standrd` - a typo of this cluster's real default
StorageClass, `standard`. Because no StorageClass named `standrd` exists, the claim sits
`Pending` forever with no provisioner ever picking it up.

`storageClassName` is immutable once a PVC exists, so it cannot be patched in place. Delete
and recreate the PersistentVolumeClaim `reports-data` with `storageClassName: standard`
(keep the same access mode `ReadWriteOnce` and the same storage request, `100Mi`) so it binds.

## Hint

Search kubernetes.io/docs for **"persistentvolumeclaim storageClassName"** - the Persistent
Volumes concept page's Class section notes that a claim requesting a StorageClass name that
does not exist never gets a provisioner assigned and stays `Pending` indefinitely, with no
error surfaced beyond the claim's own status.
