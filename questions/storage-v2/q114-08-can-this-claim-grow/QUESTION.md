# q114-08: Can this claim grow?

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-08-can-this-claim-grow`

Claim `tiber-data` (200Mi, default StorageClass) is nearly full. Team Tiber wants 500Mi.

- `(ungraded)` Try resizing `tiber-data` to 500Mi and read the API's rejection. Read the default
  StorageClass's own `allowVolumeExpansion` field.
- Create StorageClass **`q114-08-expandable`** using the **same provisioner** as the cluster's
  default class, with `allowVolumeExpansion: true`, label
  `clusterdrill-question=q114-08-can-this-claim-grow`.
- Create a **new** PVC `q114-08-new-data` (200Mi) using that class, and successfully request it
  grow to 500Mi.

## Hint

Search kubernetes.io/docs for **"Expanding Persistent Volumes Claims"**. Resizing means raising
`spec.resources.requests.storage` on the claim - whether the API allows it depends on the claim's
StorageClass, fixed at creation. A class switch on an existing claim is not possible either; only a
**new** claim on an expandable class can ever grow.
