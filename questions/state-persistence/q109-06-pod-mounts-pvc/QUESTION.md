# q109-06: Mount a PersistentVolumeClaim in a Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-06-pod-mounts-pvc`

`setup.sh` already created a PersistentVolumeClaim named `notes-pvc` (`1Gi`, `ReadWriteOnce`,
default storage class, already `Bound`) in namespace `q109-06-pod-mounts-pvc`.

Create a Pod named `notes-app` with a single container named `notes` (image `busybox:1.36`,
command that sleeps forever) that mounts `notes-pvc` at path `/data/notes` using a volume named
`notes-storage`.

## Hint

Search kubernetes.io/docs for **"persistentVolumeClaim claimName pod volume"** - the Persistent
Volumes concept page shows how a Pod's `volumes` entry references an existing PVC by
`claimName`.
