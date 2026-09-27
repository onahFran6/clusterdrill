# q109-46-pv-retain-recreate-from-released-data: Recover Retain-policy data after the PV object itself is gone

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-46-pv-retain-recreate-from-released-data`

PersistentVolume `archive-pv-old` (capacity `200Mi`, access mode `ReadWriteOnce`,
`persistentVolumeReclaimPolicy: Retain`, storage class name `""`, `hostPath` at
`/mnt/q109-46-archive`) and the PersistentVolumeClaim `archive-claim` that was bound to it
have both been deleted. The data is still on the node at `/mnt/q109-46-archive`.

Create a new PersistentVolume named `archive-pv-new` that uses that same path: capacity
`200Mi`, access mode `ReadWriteOnce`, `persistentVolumeReclaimPolicy: Retain`, storage class
name `""`, and `hostPath.path` `/mnt/q109-46-archive`. Then create a new PersistentVolumeClaim
named `archive-claim` (same access mode and storage class name, requesting `200Mi`) so it
binds to `archive-pv-new`.

## Hint

Search kubernetes.io/docs for **"persistentvolume reclaiming"** - the Persistent Volumes
concept page's Reclaiming section explains that `Retain` protects the underlying storage
asset, not any particular PersistentVolume object. Deleting the PV object left the `hostPath`
data in place; a new PV manifest pointing at the same location makes that data claimable
again.
