# q110-45-crd-ownerreference-cascade-gc: Make a ConfigMap get garbage-collected when its owning custom resource is deleted

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-45-crd-ownerreference-cascade-gc`

A CustomResourceDefinition `backupsets.ops.clusterdrill.io` (kind `BackupSet`, plural
`backupsets`, group `ops.clusterdrill.io/v1`, namespaced) is installed. Instance `nightly` and
ConfigMap `nightly-manifest` both exist in this namespace, but the ConfigMap has no
`ownerReferences`, so deleting `nightly` would leave `nightly-manifest` behind.

Add an `ownerReferences` entry on `nightly-manifest` pointing at BackupSet `nightly` -
`apiVersion: ops.clusterdrill.io/v1`, `kind: BackupSet`, `name: nightly`, and `uid` set to
`nightly`'s real UID (look it up; it changes every time the object is created). Do not delete
`nightly` or `nightly-manifest` yourself - leave both in place with the reference wired up.

## Hint

Search kubernetes.io/docs for **"owners and dependents" "garbage collection"** - the Garbage
Collection concept page explains that any object (built-in or custom-resource-backed) can name
another object as its owner via `metadata.ownerReferences`, and the garbage collector will
delete a dependent automatically once none of its owners still exist - no custom controller
required, since this is core apiserver/controller-manager behavior.
