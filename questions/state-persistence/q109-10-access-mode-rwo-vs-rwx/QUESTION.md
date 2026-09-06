# q109-10: Fix a PersistentVolumeClaim stuck Pending on an access-mode mismatch

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-10-access-mode-rwo-vs-rwx`

`setup.sh` already created:

- a PersistentVolume named `q109-10-shared-pv` (capacity `1Gi`, storage class name
  `manual-q109-10`, `hostPath`-backed) that only supports **`ReadWriteOnce`** - this cluster's
  underlying storage (`hostPath`) cannot actually provide `ReadWriteMany` semantics across
  nodes, even though nothing stops you from *requesting* it
- a PersistentVolumeClaim named `shared-claim` in namespace `q109-10-access-mode-rwo-vs-rwx`
  that asks for `ReadWriteMany` against storage class `manual-q109-10`, and is stuck `Pending`
  because no PV in that storage class can satisfy that access mode

Fix `shared-claim` so it successfully binds to `q109-10-shared-pv`, by changing only what needs
to change about the access mode it requests. Do not modify the PersistentVolume.

## Hint

Search kubernetes.io/docs for **"persistentvolume access modes ReadWriteOnce ReadWriteMany"** -
the Persistent Volumes concept page's "Access Modes" section lists which volume plugins support
which modes, and explains that a PVC only binds to a PV whose supported access modes are a
superset of what the PVC requests.
