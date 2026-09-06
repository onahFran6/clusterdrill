# q109-35-pod-mounts-pvc-and-emptydir-together: Mount a PVC and an emptyDir in the same Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-35-pod-mounts-pvc-and-emptydir-together`

`setup.sh` already created a PersistentVolumeClaim named `data-claim` (already `Bound`,
`ReadWriteOnce`, `standard` StorageClass) in namespace
`q109-35-pod-mounts-pvc-and-emptydir-together`.

Create a Pod named `report-builder` (image `busybox:1.36`, command
`["sh", "-c", "sleep 3600"]`) with **two** volumes:

- the PVC `data-claim`, mounted at `/data` (durable output)
- a new `emptyDir` volume named `scratch`, mounted at `/scratch` (throwaway working space)

## Hint

Search kubernetes.io/docs for **"Pod" "volumes"** - the Volumes concept page shows a Pod's
`spec.volumes` list accepting entries of different volume types side by side (a
`persistentVolumeClaim` entry and an `emptyDir` entry in the same list), each mounted at its
own path via a separate entry in each container's `volumeMounts`.
