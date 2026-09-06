# q109-30: Resize a PVC on a StorageClass that doesn't allow expansion

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-30-pvc-immutable-recreate-not-patch`

`setup.sh` already dynamically provisioned a PersistentVolumeClaim named `resize-test` in
namespace `q109-30-pvc-immutable-recreate-not-patch`, requesting `100Mi` from this cluster's
default StorageClass `standard`.

The application needs `250Mi` of storage instead. Check the default StorageClass `standard`
first - its `allowVolumeExpansion` field is `false`, so an in-place patch or edit of
`resize-test`'s `spec.resources.requests.storage` will be rejected by the API server.

Delete PVC `resize-test` and recreate it with the exact same name, `ReadWriteOnce` access mode,
and the default StorageClass, but requesting `250Mi` this time.

## Hint

Search kubernetes.io/docs for **"storageclass allowVolumeExpansion"** - the Storage Classes
concept page explains that only StorageClasses with `allowVolumeExpansion: true` support
resizing an existing PVC, and that otherwise a PVC's storage request is effectively immutable
once created.
