# q109-40-pvc-stuck-terminating-pod-still-attached: Free a PVC stuck Terminating because a Pod still uses it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-40-pvc-stuck-terminating-pod-still-attached`

A PersistentVolumeClaim named `session-cache` and a Pod named `session-worker` that mounts it
already exist in namespace `q109-40-pvc-stuck-terminating-pod-still-attached`. The PVC shows
`Terminating`.

Delete Pod `session-worker` so PVC `session-cache` is actually removed.

## Hint

Search kubernetes.io/docs for **"storage object in use protection"** - the Persistent Volumes
concept page's section on this feature explains that the `kubernetes.io/pvc-protection`
finalizer keeps a PVC (or PV) in `Terminating` until every Pod that references it is gone.
Deleting the PVC again does not help: the delete is already recorded and is waiting on that
finalizer. Someone deleted `session-cache` while `session-worker` was still running.
