# q109-24: Create a local PersistentVolume with node affinity

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-24-local-pv-node-affinity`

This cluster's node has a directory `/mnt/ckad-local-data` set aside on disk for one specific
Pod's exclusive use - there is no driver that can provision storage like this on demand, and
nothing else on the node should ever be handed this same directory.

Create a StorageClass named `local-storage` configured for this kind of volume: no dynamic
provisioning, and binding deferred until a consuming Pod exists (so the scheduler's node choice
and the volume's node can be reconciled). Label it
`clusterdrill-question=q109-24-local-pv-node-affinity`.

Create a PersistentVolume named `local-data-pv`, capacity **100Mi**, backed by
`/mnt/ckad-local-data` via that StorageClass, restricted so it can only ever be used by a Pod
scheduled onto the one real node in this cluster that actually has that directory. Carry label
`clusterdrill-question=q109-24-local-pv-node-affinity`.

Create a PersistentVolumeClaim named `local-data-claim` in this namespace requesting `100Mi`
against `local-storage`.

Create a Pod named `local-consumer` in this namespace running image `busybox:1.36` with
command `["sleep", "3600"]` that mounts `local-data-claim` at `/data`.

## Hint

Search kubernetes.io/docs for **"local persistent volume"** - the Volumes concept page's
"Local" section has a full example manifest to adapt, including the StorageClass and the PV's
`nodeAffinity` block. `kubectl get nodes` gets you the one real node name this cluster has to
offer.
