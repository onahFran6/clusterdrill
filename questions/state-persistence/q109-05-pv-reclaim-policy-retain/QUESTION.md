# q109-05: Change a PersistentVolume's reclaim policy to protect data

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-05-pv-reclaim-policy-retain`

A PersistentVolume named `q109-05-audit-pv` already exists (capacity `1Gi`, access mode
`ReadWriteOnce`, storage class name `manual-q109-05`, `hostPath`-backed) with reclaim policy
`Delete`.

Without deleting or recreating the PersistentVolume, change its
`persistentVolumeReclaimPolicy` to `Retain`.

## Hint

Search kubernetes.io/docs for **"persistentvolumereclaimpolicy patch retain"** - the Persistent
Volumes concept page's "Reclaiming" section explains changing the reclaim policy on an existing
PV without recreating it. `Retain` keeps the volume after its claim is removed, instead of
deleting the data automatically.
