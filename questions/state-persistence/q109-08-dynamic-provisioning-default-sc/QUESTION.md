# q109-08: Dynamically provision storage from the cluster's default StorageClass

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-08-dynamic-provisioning-default-sc`

Create a PersistentVolumeClaim named `dynamic-claim` in namespace
`q109-08-dynamic-provisioning-default-sc` that:

- requests `500Mi` of storage
- requests `ReadWriteOnce` access
- does **not** set `storageClassName` at all

Confirm it reaches `Bound` phase.

## Hint

Search kubernetes.io/docs for **"storageclass is-default-class annotation"** - the Storage
Classes concept page explains how a cluster marks one StorageClass as the default that
provisions PVCs which omit `storageClassName`. `kubectl get storageclass` shows the default via
annotation, not merely by being the only class. `Bound` means a PersistentVolume was actually
provisioned for the claim.
