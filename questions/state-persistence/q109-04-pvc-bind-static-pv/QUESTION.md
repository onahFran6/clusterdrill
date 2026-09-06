# q109-04: Claim a specific statically-provisioned PersistentVolume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-04-pvc-bind-static-pv`

`setup.sh` already created a PersistentVolume named `q109-04-static-pv` (capacity `2Gi`, access
mode `ReadWriteOnce`, storage class name `manual-q109-04`, `hostPath`-backed) and namespace
`q109-04-pvc-bind-static-pv`. No dynamic provisioner is involved for storage class
`manual-q109-04` - a PVC only binds to this PV if it asks for compatible capacity, access mode,
and storage class name.

Create a PersistentVolumeClaim named `data-claim` in namespace `q109-04-pvc-bind-static-pv`
that binds to `q109-04-static-pv`. It must request:

- `ReadWriteOnce` access
- `1Gi` of storage (less than or equal to what the PV offers)
- storage class name `manual-q109-04`

Confirm the PVC reaches `Bound` phase before considering the task complete.

## Hint

Search kubernetes.io/docs for **"persistentvolumeclaim binding"** - the Persistent Volumes
concept page's "Binding" section explains exactly which PVC fields must be compatible with a
PV's for the two to bind.
