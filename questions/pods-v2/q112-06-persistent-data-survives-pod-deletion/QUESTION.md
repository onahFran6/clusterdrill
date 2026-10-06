# q112-06: Data that outlives the Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-06-persistent-data-survives-pod-deletion`

This cluster has no dynamic storage provisioner wired up for this exercise, and a file needs to
survive Pod deletion.

- Create PersistentVolume named exactly **`q112-06-static-pv`**: **1Gi**, `ReadWriteOnce`, storage
  class name **`manual-q112-06`**, `hostPath` directory **`/mnt/q112-06-data`**
  (`DirectoryOrCreate`), label `clusterdrill-question=q112-06-persistent-data-survives-pod-deletion`.
  Use these exact names - a PersistentVolume is cluster-scoped, so a made-up name could collide
  with another session's.
- Create PVC `triton-pvc` in this namespace requesting **500Mi** with the same storage class name,
  binding to that PV.
- Pod `writer` (`busybox:1.36`) mounts the claim at `/data` and writes `saved-by-writer` to
  `/data/proof.txt`. Delete `writer`, then create Pod `reader` that prints the file.
- `(ungraded)` Before you create the PVC, predict its bound capacity once it binds: will
  `status.capacity.storage` read `500Mi` (what you asked for) or `1Gi` (what the PV actually
  holds)?

## Hint

Search kubernetes.io/docs for **"Persistent Volumes"**, the "Binding" section. A PV is
cluster-scoped and a PVC isn't - if your PVC leaves out `storageClassName`, the default
StorageClass would grab it and provision a brand new volume instead of binding to yours. A claim
reports the *PV's* actual capacity once bound, not what it originally requested.
