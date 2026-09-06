# q101-26-recover-deleted-deployment-from-history: Regenerate a deleted Deployment's manifest from a surviving ReplicaSet

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-26-recover-deleted-deployment-from-history`

A teammate ran `kubectl delete deployment catalog-svc --cascade=orphan` in namespace
`q101-26-recover-deleted-deployment-from-history` by mistake. The Deployment object is gone, but
its ReplicaSet and 3 Pods are still running unmanaged - there is no controller reconciling them
anymore.

Inspect the orphaned ReplicaSet to recover its exact pod template - every label under
`spec.template.metadata.labels`, not just `app`, plus the image and container name - then recreate
a Deployment named exactly `catalog-svc` with 3 replicas whose `spec.selector` and
`spec.template.metadata.labels` reproduce that ReplicaSet's pod template labels **exactly**. A
Deployment only truly adopts an existing ReplicaSet (rather than rolling out a brand-new one) when
its computed pod-template hash matches - which requires the recreated template to be byte-for-byte
identical to the orphaned one, labels included.

When you are done, `catalog-svc` must show 3/3 available replicas, and the exact Pods that were
already running must still be the ones running - no Pod should have been recreated.

## Hint

Search kubernetes.io/docs for **"ReplicaSet how a replicaset works"** - the concept page explains
that a Deployment only recognizes an existing ReplicaSet as up to date (rather than superseding it
with a new one) when the ReplicaSet's pod-template-hash matches the Deployment's own computed hash
for its current template - which depends on the *entire* pod template, including every label.
