# q109-05: Change a PersistentVolume's reclaim policy to protect data

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-05-pv-reclaim-policy-retain`

`setup.sh` already created a PersistentVolume named `q109-05-audit-pv` (capacity `1Gi`, access
mode `ReadWriteOnce`, storage class name `manual-q109-05`, `hostPath`-backed) with its reclaim
policy set to `Delete` - the default a careless administrator left in place. This volume holds
audit logs that must never be deleted automatically, even after whatever claims it is removed.

Without deleting or recreating the PersistentVolume, change its `persistentVolumeReclaimPolicy`
to `Retain`.

## Hint

Search kubernetes.io/docs for **"persistentvolumereclaimpolicy patch retain"** - the Persistent
Volumes concept page's "Reclaiming" section explains changing the reclaim policy on an existing
PV without recreating it.
