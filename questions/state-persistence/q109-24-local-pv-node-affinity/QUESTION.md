# q109-24: Create a local PersistentVolume with node affinity

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-24-local-pv-node-affinity`

This cluster's node has a directory `/mnt/ckad-local-data` set aside by the cluster
administrator for a `local` volume (a raw local disk/directory bound to one specific
node - unlike `hostPath`, the scheduler must be told which node the data actually
lives on).

First, find the name of this cluster's node:

```sh
kubectl get nodes
```

Create a StorageClass named `local-storage` with provisioner `kubernetes.io/no-provisioner`
and `volumeBindingMode: WaitForFirstConsumer` (required for `local` volumes, so binding is
deferred until a consuming Pod is scheduled).

Create a PersistentVolume named `local-data-pv` that:

- has capacity `100Mi`
- has access mode `ReadWriteOnce`
- uses `volumeMode: Filesystem`
- uses `storageClassName: local-storage`
- uses `spec.local.path: /mnt/ckad-local-data`
- has `spec.nodeAffinity.required` with a `nodeSelectorTerm` matching key
  `kubernetes.io/hostname`, operator `In`, and the actual node name you discovered above
  in `values`

Create a PersistentVolumeClaim named `local-data-claim` in this namespace requesting
`100Mi`, access mode `ReadWriteOnce`, `storageClassName: local-storage`.

Create a Pod named `local-consumer` in this namespace running image `busybox:1.36` with
command `["sleep", "3600"]` that mounts `local-data-claim` at `/data`.

The PersistentVolume is cluster-scoped, so it is not created inside the namespace above -
but it must still carry the same `clusterdrill-question` label as everything else in this
task, same as the StorageClass.

## Hint

Search kubernetes.io/docs for **"local persistent volume nodeAffinity"** - the Persistent
Volumes concept page's "Local" volume type section shows a full example manifest with
`spec.local.path` and `spec.nodeAffinity.required.nodeSelectorTerms`.
