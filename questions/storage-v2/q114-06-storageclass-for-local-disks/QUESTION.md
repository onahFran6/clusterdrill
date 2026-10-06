# q114-06: A StorageClass for local disks

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-06-storageclass-for-local-disks`

Pre-created local disks need to be managed through a StorageClass, so a claim isn't bound until
the scheduler knows where its pod will run.

- Create StorageClass **`q114-06-local-disk`**: provisioner `kubernetes.io/no-provisioner`,
  `volumeBindingMode: WaitForFirstConsumer`, label
  `clusterdrill-question=q114-06-storageclass-for-local-disks`. A StorageClass is cluster-scoped -
  use this exact name and label.
- Create PersistentVolume **`q114-06-local-pv`**: 1Gi, `ReadWriteOnce`, class `q114-06-local-disk`,
  `local.path: /mnt/q114-06-data`, `nodeAffinity` required matching this cluster's actual node
  name, same label. Use the exact name - a PV is cluster-scoped.
- Create PVC `thames-claim` using that class. `(ungraded)` Predict its phase before any Pod uses
  it. Create Pod `thames-app` (`busybox:1.36`) using the claim, and confirm the claim reaches
  `Bound` once it exists.

## Hint

Search kubernetes.io/docs for **"Local"** under the Volumes concept page - it has a complete
StorageClass and PV example. A local PV *requires* `nodeAffinity`. Which provisioner value means
"no provisioner"? Resolve the real node name live - `kubectl get nodes` - never hardcode it.
