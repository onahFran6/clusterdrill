# q109-09: Define a custom StorageClass

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-09-custom-storageclass-provisioner`

`setup.sh` created namespace `q109-09-custom-storageclass-provisioner` but no resources yet.

The team wants a second storage tier, distinct from the cluster's built-in default, for
workloads that are fine losing their data when deleted. Create a StorageClass named
`fast-ephemeral` that:

- uses provisioner `k8s.io/minikube-hostpath` (the same provisioner backing this cluster's
  built-in default StorageClass)
- sets `reclaimPolicy` to `Delete`
- sets `volumeBindingMode` to `Immediate`
- is **not** marked as the cluster's default StorageClass

A StorageClass is cluster-scoped, so it is not created inside the namespace above - but it must
still carry the same `clusterdrill-question` label as everything else in this task.

## Hint

Search kubernetes.io/docs for **"storageclass provisioner reclaimPolicy volumeBindingMode"** -
the Storage Classes concept page documents every field a StorageClass manifest needs, with the
provisioner field's per-plugin table further down the same page.
