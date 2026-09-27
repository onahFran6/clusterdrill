# q109-30: Resize a PVC on a StorageClass that doesn't allow expansion

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-30-pvc-immutable-recreate-not-patch`

A PersistentVolumeClaim named `resize-test` already exists in namespace
`q109-30-pvc-immutable-recreate-not-patch`, requesting `100Mi` from the default StorageClass
`standard`.

The application needs `250Mi` of storage instead. Delete PVC `resize-test` and recreate it
with the same name, `ReadWriteOnce` access mode, and the default StorageClass, requesting
`250Mi`.

## Hint

Search kubernetes.io/docs for **"storageclass allowVolumeExpansion"** - the Storage Classes
concept page explains that only StorageClasses with `allowVolumeExpansion: true` support
resizing an existing PVC. On this cluster, StorageClass `standard` has
`allowVolumeExpansion: false`, so a patch of `spec.resources.requests.storage` is rejected
and the claim has to be recreated.
