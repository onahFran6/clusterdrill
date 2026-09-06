# q109-27: Author a StorageClass with WaitForFirstConsumer binding

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-27-storageclass-waitforfirstconsumer`

`setup.sh` created namespace `q109-27-storageclass-waitforfirstconsumer` but no resources yet.

The team wants PersistentVolumeClaims to stay unbound until a Pod actually needs them, instead
of binding immediately at creation time. Create a StorageClass named `delayed-binding` that:

- uses provisioner `k8s.io/minikube-hostpath` (the same provisioner backing this cluster's
  built-in default StorageClass)
- sets `volumeBindingMode` to `WaitForFirstConsumer`

Then create a PersistentVolumeClaim named `delayed-claim` in this namespace requesting `100Mi`
of `ReadWriteOnce` storage using StorageClass `delayed-binding`. Because of the binding mode
above, this PVC should remain `Pending` until a Pod references it.

Finally, create a Pod named `consumer` (single container also named `consumer`, image
`busybox:1.36`, command that sleeps for 3600 seconds) in this namespace that mounts
`delayed-claim` at `/data`. Once the Pod is scheduled, the PVC should bind and the Pod should
reach `Running`.

## Hint

Search kubernetes.io/docs for **"volume binding mode WaitForFirstConsumer"** - the Storage
Classes concept page's Volume Binding Mode section explains why delaying binding until a
consuming Pod exists lets the scheduler pick a node before a volume is provisioned.
