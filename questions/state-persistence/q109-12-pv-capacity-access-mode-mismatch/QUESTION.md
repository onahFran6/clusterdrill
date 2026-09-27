# q109-12: Fix a PersistentVolumeClaim that's too big for its PersistentVolume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-12-pv-capacity-access-mode-mismatch`

You will find:

- a PersistentVolume named `q109-12-small-pv` (capacity `500Mi`, access mode `ReadWriteOnce`,
  storage class name `manual-q109-12`, `hostPath`-backed)
- a PersistentVolumeClaim named `oversized-claim` in namespace
  `q109-12-pv-capacity-access-mode-mismatch` requesting `2Gi` against storage class
  `manual-q109-12`, stuck `Pending`

Fix `oversized-claim` so it binds to `q109-12-small-pv`. Change only the claim's requested
storage size to something the PV can satisfy. Do not modify the PersistentVolume, and do not
request less than `100Mi`.

## Hint

Search kubernetes.io/docs for **"persistentvolumeclaim binding process"** - the Persistent
Volumes concept page's "Binding" section explains that the control plane only binds a PVC to a
PV whose capacity is greater than or equal to what the claim requests.
