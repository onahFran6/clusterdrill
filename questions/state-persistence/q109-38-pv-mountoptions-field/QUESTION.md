# q109-38-pv-mountoptions-field: Author a PersistentVolume with custom mount options

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-38-pv-mountoptions-field`

`setup.sh` created namespace `q109-38-pv-mountoptions-field` but no resources yet.

A performance-sensitive workload's storage doesn't need access-time tracking, and the platform
team wants that expressed on the volume itself rather than relying on every consumer to
remember a mount flag.

Create a PersistentVolume named `perf-data-pv` that:

- has capacity `1Gi`
- has access mode `ReadWriteOnce`
- uses `persistentVolumeReclaimPolicy: Retain`
- uses `storageClassName: ""`
- is `hostPath`-backed at `/mnt/q109-38-perf-data`
- sets `spec.mountOptions` to a list containing exactly `noatime` and `nobarrier`, in that
  order

## Hint

Search kubernetes.io/docs for **"persistentvolume mountOptions"** - the Persistent Volumes
concept page's Mount Options section shows `spec.mountOptions` as a list of extra flags passed
to the mount command for volume plugins that support it, specified on the PersistentVolume
itself rather than by each consumer.
