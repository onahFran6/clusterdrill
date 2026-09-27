# q110-47-crd-switch-storage-version: Promote a newer CRD version to be the storage version

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-47-crd-switch-storage-version`

A CustomResourceDefinition `snapshots.storagepolicy.clusterdrill.io` (kind `Snapshot`, plural
`snapshots`, group `storagepolicy.clusterdrill.io`) is installed with two versions:

- `v1beta1` - `served: true`, `storage: true`
- `v1` - `served: true`, `storage: false`

Instance `archive-q3` in this namespace was created via `v1beta1` with `spec.label: "Archive Q3"`.
There is no conversion webhook (strategy `None`); exactly one version may be the storage version
at a time.

Patch the CRD so `v1` has `storage: true` and `v1beta1` has `storage: false` (both must change
together). Both versions must remain `served: true`. Do not edit `archive-q3` directly - after
the flip it must still be readable (with `spec.label` unchanged) through both
`kubectl get snapshots.v1beta1.storagepolicy.clusterdrill.io` and
`kubectl get snapshots.v1.storagepolicy.clusterdrill.io`.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "storage version"** - the CRD docs'
Versions section explains that exactly one version must be marked `storage: true` at all times,
and that flipping which version is the storage version is safe (existing objects stay readable
through any served version) precisely because there is no conversion webhook rewriting data
between genuinely different schemas here.
