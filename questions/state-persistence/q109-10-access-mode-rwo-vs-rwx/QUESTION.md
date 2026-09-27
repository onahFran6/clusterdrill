# q109-10: Fix a PersistentVolumeClaim stuck Pending on an access-mode mismatch

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-10-access-mode-rwo-vs-rwx`

You will find:

- a PersistentVolume named `q109-10-shared-pv` (capacity `1Gi`, storage class name
  `manual-q109-10`, `hostPath`-backed) whose only access mode is `ReadWriteOnce`
- a PersistentVolumeClaim named `shared-claim` in namespace
  `q109-10-access-mode-rwo-vs-rwx` that requests `ReadWriteMany` against storage class
  `manual-q109-10` and is stuck `Pending`

Fix `shared-claim` so it binds to `q109-10-shared-pv`. Change only the access mode it
requests. Do not modify the PersistentVolume.

## Hint

Search kubernetes.io/docs for **"persistentvolume access modes ReadWriteOnce ReadWriteMany"** -
the Persistent Volumes concept page's "Access Modes" section lists which volume plugins support
which modes. `hostPath` cannot provide `ReadWriteMany` across nodes. A PVC binds only to a PV
whose access modes are a superset of what the claim requests.
