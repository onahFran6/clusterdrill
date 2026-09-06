# q110-45-crd-ownerreference-cascade-gc: Make a ConfigMap get garbage-collected when its owning custom resource is deleted

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-45-crd-ownerreference-cascade-gc`

`setup.sh` already registered a CustomResourceDefinition `backupsets.ops.clusterdrill.io` (kind
`BackupSet`, plural `backupsets`, group `ops.clusterdrill.io/v1`, namespaced) and created an
instance `nightly` in namespace `q110-45-crd-ownerreference-cascade-gc`. It also created a
ConfigMap named `nightly-manifest` that is logically "owned" by `nightly` (it holds the backup
set's file manifest) - but nothing on the ConfigMap actually says so yet: it carries no
`ownerReferences`, so deleting `nightly` today would leave `nightly-manifest` behind forever, an
orphan with no controller cleaning it up (there is no real controller running for this CRD in
this cluster - Kubernetes's built-in garbage collector is the only mechanism available).

Add an `ownerReferences` entry to the existing `nightly-manifest` ConfigMap pointing at the
`nightly` BackupSet instance - `apiVersion: ops.clusterdrill.io/v1`, `kind: BackupSet`,
`name: nightly`, and `uid` set to `nightly`'s **actual, real UID** (look it up - it's different
every time the object is created, so it cannot be hardcoded). **Do not delete `nightly` or
`nightly-manifest` yourself** - leave both in place with the reference wired up; grading deletes
`nightly` itself afterward to confirm the cascade actually works, so a ConfigMap you deleted by
hand instead of correctly wiring up would not prove anything.

## Hint

Search kubernetes.io/docs for **"owners and dependents" "garbage collection"** - the Garbage
Collection concept page explains that any object (built-in or custom-resource-backed) can name
another object as its owner via `metadata.ownerReferences`, and the garbage collector will
delete a dependent automatically once none of its owners still exist - no custom controller
required, since this is core apiserver/controller-manager behavior.
