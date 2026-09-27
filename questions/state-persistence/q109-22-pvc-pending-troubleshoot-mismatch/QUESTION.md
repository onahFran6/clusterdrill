# q109-22-pvc-pending-troubleshoot-mismatch: Fix a PVC stuck Pending because its PV is too small

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-22-pvc-pending-troubleshoot-mismatch`

You will find:

- a PersistentVolume named `fix-me-pv` (capacity `50Mi`, access mode `ReadWriteOnce`, storage
  class name `""`, `hostPath`-backed at `/tmp/ckad-fix-me-pv`)
- a PersistentVolumeClaim named `fix-me-claim` in namespace
  `q109-22-pvc-pending-troubleshoot-mismatch` requesting `200Mi` with access mode
  `ReadWriteOnce` and storage class name `""`, stuck `Pending`

Make `fix-me-claim` bind to `fix-me-pv`. The PersistentVolume must end with capacity of at
least `200Mi`, the same `hostPath` (`/tmp/ckad-fix-me-pv`), the same access mode
`ReadWriteOnce`, and the same storage class name `""`.

## Hint

Search kubernetes.io/docs for **"persistentvolumeclaim binding process"** - the Persistent
Volumes concept page's "Binding" section explains that a claim only binds to a volume whose
capacity is greater than or equal to what the claim requests. PersistentVolume capacity cannot
be changed after creation, so delete and recreate `fix-me-pv` rather than patching it.
