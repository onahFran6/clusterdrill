# q109-33-storageclass-level-reclaim-policy: Author a StorageClass whose dynamically-provisioned PVs default to Retain

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-33-storageclass-level-reclaim-policy`

`setup.sh` created namespace `q109-33-storageclass-level-reclaim-policy` but no resources yet.

Every PersistentVolume dynamically provisioned from this cluster's built-in default
StorageClass gets `persistentVolumeReclaimPolicy: Delete` - fine for scratch data, but wrong
for a compliance-sensitive workload that must never lose data just because someone deletes its
PVC.

Create a StorageClass named `compliance-storage` that:

- uses provisioner `k8s.io/minikube-hostpath` (the same provisioner backing the built-in
  default)
- sets `reclaimPolicy` to `Retain`, so every PV it dynamically provisions inherits `Retain`
  automatically, with no per-PV patching needed afterward
- sets `volumeBindingMode` to `Immediate`
- is **not** marked as the cluster's default StorageClass

A StorageClass is cluster-scoped, so it is not created inside the namespace above - but it must
still carry the same `clusterdrill-question` label as everything else in this task.

## Hint

Search kubernetes.io/docs for **"storageclass reclaimPolicy"** - the Storage Classes concept
page's Reclaim Policy section explains that `spec.reclaimPolicy` on a StorageClass (distinct
from patching an individual PersistentVolume after the fact) sets the default reclaim policy
every PersistentVolume dynamically provisioned from that class is created with.
