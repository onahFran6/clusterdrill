# q109-20-pvc-bind-via-selector-empty-storageclass: Bind a PVC to a specific pre-existing PV using a label selector

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-20-pvc-bind-via-selector-empty-storageclass`

Two static PersistentVolumes already exist in this cluster (both `hostPath`-backed, `100Mi`
capacity, `ReadWriteOnce` access, `storageClassName: ""`):

- `vol-blue`, labeled `env=blue`
- `vol-green`, labeled `env=green`

Create a PersistentVolumeClaim named `env-claim` in namespace
`q109-20-pvc-bind-via-selector-empty-storageclass` that binds specifically to `vol-green`. It
must request:

- `storageClassName: ""`
- `100Mi` of storage
- `ReadWriteOnce` access
- a `selector.matchLabels` of `env: green`

Confirm the PVC reaches `Bound` phase and that `spec.volumeName` is exactly `vol-green`.

## Hint

Search kubernetes.io/docs for **"PersistentVolumeClaim selector matchLabels"** - the Persistent
Volumes concept page's "Binding" section covers how a claim's `selector` narrows binding to PVs
whose labels match. These two PVs match on capacity and access mode, so the selector is what
picks `vol-green` over `vol-blue`. `storageClassName: ""` opts out of the default StorageClass
and dynamic provisioning so the claim binds to an existing volume.
