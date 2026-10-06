# q114-04: Reserve a volume for a future claim

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-04-reserve-for-a-future-claim`

PVs `q114-04-a` and `q114-04-b` are identical (1Gi, `ReadWriteOnce`, StorageClass
`manual-q114-04`).

- Patch `q114-04-a`'s `claimRef` to reserve it for a claim named `reserved` in this namespace,
  which doesn't exist yet. No other claim may take it.
- Create PVC `volga-claim` bound specifically to `q114-04-b` via `volumeName`.
- Create PVC `other` (same class, no pin). `(ungraded)` Confirm it stays `Pending` - both real PVs
  are already spoken for, and the class has no provisioner.
- Finally create PVC `reserved` and confirm it binds to `q114-04-a`.

## Hint

Search kubernetes.io/docs for **"Persistent Volumes"**, the `claimRef` field under
`PersistentVolumeSpec`. Binding can be pinned from either side: the claim has a field naming the
volume (`volumeName`), and the volume has a field naming the claim (`claimRef`: namespace + name).
Set the volume side *before* creating `other`.
