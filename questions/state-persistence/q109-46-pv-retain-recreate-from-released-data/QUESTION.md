# q109-46-pv-retain-recreate-from-released-data: Recover Retain-policy data after the PV object itself is gone

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-46-pv-retain-recreate-from-released-data`

`setup.sh` already:

- created a PersistentVolume named `archive-pv-old` (capacity `200Mi`, access mode
  `ReadWriteOnce`, `persistentVolumeReclaimPolicy: Retain`, storage class name `""`,
  `hostPath`-backed at `/mnt/q109-46-archive`) and a PersistentVolumeClaim `archive-claim` bound
  to it
- deleted `archive-claim`, then deleted the PersistentVolume object `archive-pv-old` itself

Because the reclaim policy was `Retain`, deleting the PV object never touched the underlying
`hostPath` data at `/mnt/q109-46-archive` - it is still there on the node, just with no
PersistentVolume object pointing at it anymore, and no way to reclaim a PV object that no longer
exists.

Create a **new** PersistentVolume named `archive-pv-new` that adopts that same retained data:
capacity `200Mi`, access mode `ReadWriteOnce`, `persistentVolumeReclaimPolicy: Retain`, storage
class name `""`, and `hostPath.path` set to the same path, `/mnt/q109-46-archive`. Then create a
new PersistentVolumeClaim named `archive-claim` (same access mode and storage class name,
requesting `200Mi`) so it binds to `archive-pv-new`.

## Hint

Search kubernetes.io/docs for **"persistentvolume reclaiming"** - the Persistent Volumes
concept page's Reclaiming section explains that `Retain` only protects the underlying storage
asset, not any particular PersistentVolume *object* representing it - if that object is deleted
too, a brand new PV manifest pointing at the same location is the only way to make the data
claimable again.
