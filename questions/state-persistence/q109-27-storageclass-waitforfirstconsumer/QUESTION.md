# q109-27: Author a StorageClass with WaitForFirstConsumer binding

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-27-storageclass-waitforfirstconsumer`

Create a StorageClass named `delayed-binding` that:

- uses provisioner `k8s.io/minikube-hostpath`
- sets `volumeBindingMode` to `WaitForFirstConsumer`

Then create a PersistentVolumeClaim named `delayed-claim` in this namespace requesting `100Mi`
of `ReadWriteOnce` storage using StorageClass `delayed-binding`.

Finally, create a Pod named `consumer` (single container also named `consumer`, image
`busybox:1.36`, command that sleeps for 3600 seconds) in this namespace that mounts
`delayed-claim` at `/data`. The Pod should reach `Running` and the PVC should be `Bound`.

## Hint

Search kubernetes.io/docs for **"volume binding mode WaitForFirstConsumer"** - the Storage
Classes concept page's Volume Binding Mode section explains why delaying binding until a
consuming Pod exists lets the scheduler pick a node before a volume is provisioned.
`k8s.io/minikube-hostpath` is the provisioner backing this cluster's built-in default
StorageClass. With this binding mode the PVC stays `Pending` until a Pod references it.
A StorageClass is cluster-scoped.
