# q109-18: Create a static PersistentVolume with reclaim policy Delete

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-18-pv-reclaim-policy-delete`

Create a PersistentVolume named `scratch-pv` that:

- has capacity `50Mi`
- has access mode `ReadWriteOnce`
- uses `hostPath` pointing at `/tmp/ckad-scratch-pv`
- uses storage class name `""` (empty string)
- has reclaim policy `Delete`
- carries label `clusterdrill-question=q109-18-pv-reclaim-policy-delete`

## Hint

Search kubernetes.io/docs for **"persistentVolumeReclaimPolicy"** - the Persistent Volumes
concept page's Reclaiming section explains the `Retain`, `Delete`, and (deprecated) `Recycle`
policies and shows how to set `persistentVolumeReclaimPolicy` on a static PV manifest. An empty
`storageClassName` means this PV is not bound via any StorageClass. A PersistentVolume is
cluster-scoped, so it is not created inside the question namespace.
