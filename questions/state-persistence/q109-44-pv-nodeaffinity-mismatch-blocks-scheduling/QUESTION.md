# q109-44-pv-nodeaffinity-mismatch-blocks-scheduling: Fix a local PV whose nodeAffinity points at the wrong node

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-44-pv-nodeaffinity-mismatch-blocks-scheduling`

`setup.sh` already created, in namespace `q109-44-pv-nodeaffinity-mismatch-blocks-scheduling`:

- a `local` PersistentVolume named `metrics-local-pv` (capacity `100Mi`, access mode
  `ReadWriteOnce`, `storageClassName: local-storage-q109-44`, `spec.local.path:
  /mnt/q109-44-metrics`) whose `spec.nodeAffinity.required` names a node,
  `ckad-worker-99`, that does not exist on this cluster
- a StorageClass `local-storage-q109-44` (`WaitForFirstConsumer`)
- a PersistentVolumeClaim `metrics-claim` requesting `100Mi` from that StorageClass
- a Pod `metrics-collector` mounting `metrics-claim` at `/data`

Because `WaitForFirstConsumer` defers binding, `metrics-claim` shows `Pending` (not yet an
error) - but `metrics-collector` itself is stuck `Pending` too: the scheduler can never place it
anywhere, because the only PV that could satisfy its claim is affine to a node
(`ckad-worker-99`) that isn't part of this cluster.

Find this cluster's real node:

```sh
kubectl get nodes -o jsonpath='{.items[0].metadata.labels.kubernetes\.io/hostname}'
```

`nodeAffinity` cannot be patched on an existing PersistentVolume - delete and recreate
`metrics-local-pv` with `spec.nodeAffinity.required` corrected to name the real node instead of
`ckad-worker-99`, keeping every other field the same. Once fixed, `metrics-claim` should bind
and `metrics-collector` should reach `Running`.

## Hint

Search kubernetes.io/docs for **"local persistent volume nodeAffinity"** - the Persistent
Volumes concept page's "Local" volume type section explains that `local` volumes require
`nodeAffinity` to tell the scheduler which specific node the data actually lives on, and a Pod
whose only viable PV is affine to a node that doesn't exist can never be scheduled.
