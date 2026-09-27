# q101-26: Recover a deleted Deployment from its orphaned ReplicaSet

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-26-recover-deleted-deployment-from-history`

Someone ran `kubectl delete deployment catalog-svc --cascade=orphan` in namespace
`q101-26-recover-deleted-deployment-from-history`. The Deployment is gone, but its ReplicaSet and
3 Pods are still running unmanaged.

Inspect the orphaned ReplicaSet and recreate a Deployment named exactly `catalog-svc` with 3
replicas whose `spec.selector` and `spec.template.metadata.labels` match that ReplicaSet's pod
template labels exactly (every label, not just `app`), along with the same image and container
name. The recreated template must match the orphaned one closely enough that the Deployment adopts
the existing ReplicaSet instead of rolling out a new one.

When you are done, `catalog-svc` must show 3/3 available replicas, and the Pods that were already
running must still be the ones running - no Pod should have been recreated.

## Hint

Search kubernetes.io/docs for **"ReplicaSet how a replicaset works"** - the concept page explains
that a Deployment only recognizes an existing ReplicaSet as up to date (rather than superseding it
with a new one) when the ReplicaSet's pod-template-hash matches the Deployment's own computed hash
for its current template - which depends on the *entire* pod template, including every label.
