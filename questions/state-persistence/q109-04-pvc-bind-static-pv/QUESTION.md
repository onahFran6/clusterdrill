# q109-04: Claim a specific statically-provisioned PersistentVolume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-04-pvc-bind-static-pv`

A PersistentVolume named `q109-04-static-pv` already exists (capacity `2Gi`, access mode
`ReadWriteOnce`, storage class name `manual-q109-04`, `hostPath`-backed).

Create a PersistentVolumeClaim named `data-claim` in namespace `q109-04-pvc-bind-static-pv`
that binds to `q109-04-static-pv`. It must request:

- `ReadWriteOnce` access
- `1Gi` of storage
- storage class name `manual-q109-04`

Confirm the PVC reaches `Bound` phase before considering the task complete.

## Hint

Search kubernetes.io/docs for **"persistentvolumeclaim binding"** - the Persistent Volumes
concept page's "Binding" section explains exactly which PVC fields must be compatible with a
PV's for the two to bind. No dynamic provisioner serves storage class `manual-q109-04`.
