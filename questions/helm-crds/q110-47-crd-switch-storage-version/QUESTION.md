# q110-47-crd-switch-storage-version: Promote a newer CRD version to be the storage version

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-47-crd-switch-storage-version`

`setup.sh` already registered a CustomResourceDefinition `snapshots.storagepolicy.clusterdrill.io`
(kind `Snapshot`, plural `snapshots`, group `storagepolicy.clusterdrill.io`) with two versions:

- `v1beta1` - `served: true`, `storage: true` (the current storage version)
- `v1` - `served: true`, `storage: false`

and created an instance `archive-q3` in namespace `q110-47-crd-switch-storage-version` via
`v1beta1`, with `spec.label: "Archive Q3"`. The team has finished migrating and now wants `v1`
(not `v1beta1`) to be the version new objects get stored as - but with **no conversion webhook
configured** (this CRD uses the default `None` conversion strategy), only **one** version may be
the storage version at a time, and this CRD's two schemas are already identical, so no actual
conversion logic is needed - it's a pure flip.

Patch the CRD so `v1`'s `storage` is `true` and `v1beta1`'s `storage` is `false` (**both** must
change together - the API rejects a CRD with zero or more than one storage version). Both
versions must remain `served: true`. Do not touch the `archive-q3` instance directly - once the
storage version is flipped, it must still be readable (with `spec.label` unchanged) through
**both** `kubectl get snapshots.v1beta1.storagepolicy.clusterdrill.io` and
`kubectl get snapshots.v1.storagepolicy.clusterdrill.io`.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "storage version"** - the CRD docs'
Versions section explains that exactly one version must be marked `storage: true` at all times,
and that flipping which version is the storage version is safe (existing objects stay readable
through any served version) precisely because there is no conversion webhook rewriting data
between genuinely different schemas here.
