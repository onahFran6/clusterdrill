# q109-34-fix-pvc-storageclassname-typo: Fix a PVC stuck Pending on a typo'd StorageClass name

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-34-fix-pvc-storageclassname-typo`

A PersistentVolumeClaim named `reports-data` already exists in namespace
`q109-34-fix-pvc-storageclassname-typo`. It requests `100Mi` with access mode
`ReadWriteOnce` and is stuck `Pending`.

Delete and recreate PersistentVolumeClaim `reports-data` so `storageClassName` is `standard`
(this cluster's default StorageClass). Keep access mode `ReadWriteOnce` and the `100Mi`
request so the claim binds.

## Hint

Search kubernetes.io/docs for **"persistentvolumeclaim storageClassName"** - the Persistent
Volumes concept page's Class section notes that a claim requesting a StorageClass name that
does not exist never gets a provisioner assigned and stays `Pending`. `storageClassName` is
immutable, so it cannot be patched in place. Inspect the claim's current `storageClassName`
before recreating it.
