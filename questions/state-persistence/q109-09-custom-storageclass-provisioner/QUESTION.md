# q109-09: Define a custom StorageClass

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-09-custom-storageclass-provisioner`

Create a StorageClass named `fast-ephemeral` that:

- uses provisioner `k8s.io/minikube-hostpath`
- sets `reclaimPolicy` to `Delete`
- sets `volumeBindingMode` to `Immediate`
- is **not** marked as the cluster's default StorageClass
- carries label `clusterdrill-question=q109-09-custom-storageclass-provisioner`

## Hint

Search kubernetes.io/docs for **"storageclass provisioner reclaimPolicy volumeBindingMode"** -
the Storage Classes concept page documents every field a StorageClass manifest needs.
`k8s.io/minikube-hostpath` is the provisioner backing this cluster's built-in default class.
A StorageClass is cluster-scoped, so it is not created inside the question namespace.
