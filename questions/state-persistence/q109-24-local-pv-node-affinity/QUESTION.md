# q109-24: Create a local PersistentVolume with node affinity

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-24-local-pv-node-affinity`

This cluster's node has a directory `/mnt/ckad-local-data` set aside for a `local` volume.

Create a StorageClass named `local-storage` with provisioner `kubernetes.io/no-provisioner`
and `volumeBindingMode: WaitForFirstConsumer`. Label it
`clusterdrill-question=q109-24-local-pv-node-affinity`.

Create a PersistentVolume named `local-data-pv` that:

- has capacity `100Mi`
- has access mode `ReadWriteOnce`
- uses `volumeMode: Filesystem`
- uses `storageClassName: local-storage`
- uses `spec.local.path: /mnt/ckad-local-data`
- has `spec.nodeAffinity.required` with a `nodeSelectorTerm` matching key
  `kubernetes.io/hostname`, operator `In`, and this cluster's real node name in `values`
- carries label `clusterdrill-question=q109-24-local-pv-node-affinity`

Create a PersistentVolumeClaim named `local-data-claim` in this namespace requesting `100Mi`,
access mode `ReadWriteOnce`, `storageClassName: local-storage`.

Create a Pod named `local-consumer` in this namespace running image `busybox:1.36` with
command `["sleep", "3600"]` that mounts `local-data-claim` at `/data`.

## Hint

Search kubernetes.io/docs for **"local persistent volume nodeAffinity"** - the Persistent
Volumes concept page's "Local" volume type section shows a full example manifest with
`spec.local.path` and `spec.nodeAffinity.required.nodeSelectorTerms`. Unlike `hostPath`, the
scheduler must be told which node holds the data. `WaitForFirstConsumer` defers binding until
a consuming Pod is scheduled. `kubectl get nodes` shows the node name to put in affinity
`values`. Both the StorageClass and the PersistentVolume are cluster-scoped.
