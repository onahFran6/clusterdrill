# q109-48-multi-pvc-different-storageclasses-one-pod: Mount two PVCs from two different StorageClasses in one Pod

**Domain:** Application Design and Build · **Points:** 6 · **Namespace:** `q109-48-multi-pvc-different-storageclasses-one-pod`

`setup.sh` already created two StorageClasses:

- `fast-tier` (provisioner `k8s.io/minikube-hostpath`, `reclaimPolicy: Delete`)
- `durable-tier` (provisioner `k8s.io/minikube-hostpath`, `reclaimPolicy: Retain`)

Create two PersistentVolumeClaims in namespace
`q109-48-multi-pvc-different-storageclasses-one-pod`, each requesting `ReadWriteOnce`:

- `cache-claim` requesting `100Mi` via StorageClass `fast-tier`
- `records-claim` requesting `200Mi` via StorageClass `durable-tier`

Then create a Pod named `data-processor` (image `busybox:1.36`, command
`["sh", "-c", "sleep 3600"]`) that mounts **both** claims in the same container: `cache-claim`
at `/cache` and `records-claim` at `/records`.

## Hint

Search kubernetes.io/docs for **"Pod" "multiple" "persistentVolumeClaim"** - the Volumes
concept page shows a Pod's `spec.volumes` list can reference more than one
`persistentVolumeClaim` entry, each backed by whichever StorageClass its own PVC requested - a
single Pod is not limited to volumes from one storage tier.
