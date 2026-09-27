# q109-33-storageclass-level-reclaim-policy: Author a StorageClass whose dynamically-provisioned PVs default to Retain

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-33-storageclass-level-reclaim-policy`

Create a StorageClass named `compliance-storage` that:

- uses provisioner `k8s.io/minikube-hostpath`
- sets `reclaimPolicy` to `Retain`
- sets `volumeBindingMode` to `Immediate`
- is **not** marked as the cluster's default StorageClass
- carries label `clusterdrill-question=q109-33-storageclass-level-reclaim-policy`

## Hint

Search kubernetes.io/docs for **"storageclass reclaimPolicy"** - the Storage Classes concept
page's Reclaim Policy section explains that `spec.reclaimPolicy` on a StorageClass sets the
reclaim policy of every PersistentVolume that class provisions. The built-in default class on
this cluster uses `Delete`. `k8s.io/minikube-hostpath` is that default class's provisioner. A
StorageClass is cluster-scoped, so it is not created inside the question namespace.
