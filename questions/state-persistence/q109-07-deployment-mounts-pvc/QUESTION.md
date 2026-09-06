# q109-07: Back a Deployment's data directory with a PVC

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-07-deployment-mounts-pvc`

`setup.sh` already created a PersistentVolumeClaim named `uploads-pvc` (`1Gi`, `ReadWriteOnce`,
default storage class, already `Bound`) in namespace `q109-07-deployment-mounts-pvc`.

Create a Deployment named `uploads-api` with:

- `1` replica
- container named `api`, image `nginx:1.25-alpine`
- the PVC `uploads-pvc` mounted at `/usr/share/nginx/html/uploads` via a volume named
  `uploads-storage`

Because the PVC's access mode is `ReadWriteOnce`, keep the replica count at `1` - scaling this
Deployment further would leave additional pods unable to mount the same volume on this cluster.

## Hint

Search kubernetes.io/docs for **"deployment persistentVolumeClaim volumes template"** - the
Persistent Volumes concept page's "claims as volumes" example generalizes directly into a
Deployment's pod template spec.
