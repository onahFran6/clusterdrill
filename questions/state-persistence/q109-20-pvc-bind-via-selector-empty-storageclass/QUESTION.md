# q109-20-pvc-bind-via-selector-empty-storageclass: Bind a PVC to a specific pre-existing PV using a label selector

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-20-pvc-bind-via-selector-empty-storageclass`

`setup.sh` already created two static PersistentVolumes in this cluster (both `hostPath`-backed,
`100Mi` capacity, `ReadWriteOnce` access, `storageClassName: ""`):

- `vol-blue`, labeled `env=blue`
- `vol-green`, labeled `env=green`

Both PVs are otherwise identical in capacity and access mode, so capacity/access-mode matching
alone cannot tell them apart - a PVC needs a label selector to pick one over the other.

Create a PersistentVolumeClaim named `env-claim` in namespace
`q109-20-pvc-bind-via-selector-empty-storageclass` that binds specifically to `vol-green` (not
`vol-blue`). It must request:

- `storageClassName: ""` (empty string - matches the PVs' empty storage class, opting out of the
  default StorageClass and dynamic provisioning)
- `100Mi` of storage
- `ReadWriteOnce` access
- a `selector.matchLabels` of `env: green`

Confirm the PVC reaches `Bound` phase and that `spec.volumeName` is exactly `vol-green` before
considering the task complete.

## Hint

Search kubernetes.io/docs for **"PersistentVolumeClaim selector matchLabels"** - the Persistent
Volumes concept page's "Binding" section covers how a claim's `selector` narrows binding to PVs
whose labels match, and why `storageClassName: ""` is required to prevent the default
StorageClass from dynamically provisioning a new volume instead of binding to an existing one.
