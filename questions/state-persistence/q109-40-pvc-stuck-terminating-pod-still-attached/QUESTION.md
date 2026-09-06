# q109-40-pvc-stuck-terminating-pod-still-attached: Free a PVC stuck Terminating because a Pod still uses it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-40-pvc-stuck-terminating-pod-still-attached`

`setup.sh` already created a PersistentVolumeClaim named `session-cache` and a Pod named
`session-worker` that mounts it, in namespace `q109-40-pvc-stuck-terminating-pod-still-attached`.
Someone ran `kubectl delete pvc session-cache` while `session-worker` was still running - the
PVC now shows `Terminating` in `kubectl get pvc` and has sat that way ever since.

The `kubernetes.io/pvc-protection` finalizer on a PersistentVolumeClaim blocks its actual
deletion for as long as any Pod still references it, specifically to prevent silently pulling
storage out from under a running workload. `kubectl delete pvc` again will not help - the delete
already happened and is just waiting on the finalizer.

Delete the Pod `session-worker` first, which lets the finalizer clear and the PVC actually
disappear.

## Hint

Search kubernetes.io/docs for **"storage object in use protection"** - the Persistent Volumes
concept page's section on this feature explains that a PVC (or PV) with an in-use finalizer
present stays in the `Terminating` state, not actually removed, until every Pod that references
it is deleted.
