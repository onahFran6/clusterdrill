# q109-08: Dynamically provision storage from the cluster's default StorageClass

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-08-dynamic-provisioning-default-sc`

`setup.sh` created namespace `q109-08-dynamic-provisioning-default-sc` but no resources yet.
This cluster already has exactly one StorageClass marked as the cluster default (check
`kubectl get storageclass` - the default is annotated, not just "the only one").

Create a PersistentVolumeClaim named `dynamic-claim` that:

- requests `500Mi` of storage
- requests `ReadWriteOnce` access
- does **not** set `storageClassName` at all, so it dynamically provisions from whichever
  StorageClass the cluster has marked as default

Confirm it reaches `Bound` phase - that's the signal a PersistentVolume was actually
provisioned for it, not just requested.

## Hint

Search kubernetes.io/docs for **"storageclass is-default-class annotation"** - the Storage
Classes concept page explains how a cluster marks one StorageClass as the default that
provisions PVCs which omit `storageClassName`.
