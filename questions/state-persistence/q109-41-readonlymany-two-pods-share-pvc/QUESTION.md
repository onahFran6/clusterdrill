# q109-41-readonlymany-two-pods-share-pvc: Mount one PVC read-only from two Pods at once

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-41-readonlymany-two-pods-share-pvc`

`setup.sh` already created a PersistentVolume named `shared-catalog-pv` (capacity `100Mi`,
access mode `ReadOnlyMany`, `hostPath`-backed, storage class name `""`) and a
PersistentVolumeClaim named `catalog-claim` (already `Bound` to it, access mode
`ReadOnlyMany`, storage class name `""`) in namespace
`q109-41-readonlymany-two-pods-share-pvc`.

Create **two** Pods, `catalog-reader-a` and `catalog-reader-b` (both image `busybox:1.36`,
command `["sh", "-c", "sleep 3600"]`), each mounting `catalog-claim` at `/catalog` with
`readOnly: true` on the volume mount. Both Pods must be able to run **simultaneously** - unlike
`ReadWriteOnce`, `ReadOnlyMany` allows the same volume to be mounted by more than one Pod at
once, as long as every mount is read-only.

## Hint

Search kubernetes.io/docs for **"persistentvolume access modes"** - the Persistent Volumes
concept page's Access Modes section explains that `ReadOnlyMany` (`ROX`) lets a volume be
mounted read-only by many nodes/Pods simultaneously, unlike `ReadWriteOnce` which restricts a
volume to being mounted read-write by only one node at a time.
