# q109-07: Back a Deployment's data directory with a PVC

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-07-deployment-mounts-pvc`

A PersistentVolumeClaim named `uploads-pvc` (`1Gi`, `ReadWriteOnce`, default storage class,
already `Bound`) already exists in namespace `q109-07-deployment-mounts-pvc`.

Create a Deployment named `uploads-api` with:

- `1` replica
- container named `api`, image `nginx:1.25-alpine`
- the PVC `uploads-pvc` mounted at `/usr/share/nginx/html/uploads` via a volume named
  `uploads-storage`

## Hint

Search kubernetes.io/docs for **"deployment persistentVolumeClaim volumes template"** - the
Persistent Volumes concept page's "claims as volumes" example generalizes directly into a
Deployment's pod template spec. This claim is `ReadWriteOnce`, so extra replicas on this
cluster would be unable to mount the same volume.
