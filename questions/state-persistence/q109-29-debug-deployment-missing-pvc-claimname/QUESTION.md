# q109-29-debug-deployment-missing-pvc-claimname: Fix a Deployment stuck Pending from a typo'd PVC claimName

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-29-debug-deployment-missing-pvc-claimname`

You will find:

- a PersistentVolumeClaim named `orders-data` (`100Mi`, `ReadWriteOnce`, default storage
  class, dynamically provisioned and `Bound`) in namespace
  `q109-29-debug-deployment-missing-pvc-claimname`
- a Deployment named `orders-api` (`1` replica, image `busybox:1.36`, command `sleep 3600`)
  whose pod stays `Pending`

Fix the Deployment `orders-api` so its pod template's `persistentVolumeClaim.claimName` is
`orders-data` (do not rename or recreate the PVC). The pod should go `Running` and the
Deployment should have `1` ready replica.

## Hint

Search kubernetes.io/docs for **"pod stuck pending persistentvolumeclaim"** - the
Troubleshooting Applications section on debugging Pods covers checking `kubectl describe
pod` events for volume-mount and unbound-claim failures, and the Configure a Pod to Use
a PersistentVolume for Storage task shows the correct `claimName` field under
`spec.volumes`. The Deployment currently names a claim that does not exist.
