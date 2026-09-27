# q109-44-pv-nodeaffinity-mismatch-blocks-scheduling: Fix a local PV whose nodeAffinity points at the wrong node

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-44-pv-nodeaffinity-mismatch-blocks-scheduling`

In namespace `q109-44-pv-nodeaffinity-mismatch-blocks-scheduling` you will find:

- a `local` PersistentVolume named `metrics-local-pv` (capacity `100Mi`, access mode
  `ReadWriteOnce`, `storageClassName: local-storage-q109-44`, `spec.local.path:
  /mnt/q109-44-metrics`) whose `spec.nodeAffinity.required` does not match a node in this
  cluster
- a StorageClass `local-storage-q109-44` (`WaitForFirstConsumer`)
- a PersistentVolumeClaim `metrics-claim` requesting `100Mi` from that StorageClass
- a Pod `metrics-collector` mounting `metrics-claim` at `/data`, stuck `Pending`

Recreate `metrics-local-pv` so `spec.nodeAffinity.required` names this cluster's real node.
Keep every other field the same. `metrics-claim` should bind and `metrics-collector` should
reach `Running`.

## Hint

Search kubernetes.io/docs for **"local persistent volume nodeAffinity"** - the Persistent
Volumes concept page's "Local" volume type section explains that `local` volumes require
`nodeAffinity` so the scheduler knows which node holds the data. `nodeAffinity` cannot be
patched on an existing PersistentVolume. With `WaitForFirstConsumer`, the PVC stays `Pending`
until a Pod can be placed; a PV affine to a missing node can never be scheduled. The current
affinity names `ckad-worker-99`. This command prints the real hostname:

```sh
kubectl get nodes -o jsonpath='{.items[0].metadata.labels.kubernetes\.io/hostname}'
```
