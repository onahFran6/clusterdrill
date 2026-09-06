# q109-18: Create a static PersistentVolume with reclaim policy Delete

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-18-pv-reclaim-policy-delete`

`setup.sh` created namespace `q109-18-pv-reclaim-policy-delete` but no resources yet.

Create a PersistentVolume named `scratch-pv` that:

- has capacity `50Mi`
- has access mode `ReadWriteOnce`
- uses `hostPath` pointing at `/tmp/ckad-scratch-pv`
- uses storage class name `""` (empty string - this PV is not bound via any StorageClass)
- has reclaim policy `Delete`

A PersistentVolume is cluster-scoped, so it is not created inside the namespace above - but it
must still carry the same `clusterdrill-question` label as everything else in this task.

## Hint

Search kubernetes.io/docs for **"persistentVolumeReclaimPolicy"** - the Persistent Volumes
concept page's Reclaiming section explains the `Retain`, `Delete`, and (deprecated) `Recycle`
policies and shows how to set `persistentVolumeReclaimPolicy` on a static PV manifest.
