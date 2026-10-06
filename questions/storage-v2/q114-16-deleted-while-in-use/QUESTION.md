# q114-16: Deleted while in use

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-16-deleted-while-in-use`

Someone ran `kubectl delete pvc data` while Pod `app` was still using it. The command hung, and
this team now wants to **keep** the data even though the claim will go.

- `(ungraded)` Note the claim's `Terminating` status and its finalizer.
- Make sure the underlying volume and its data survive anyway - patch its reclaim policy to
  `Retain` **before** freeing it up. Then delete Pod `app` so the claim's finalizer can clear.

## Hint

Search kubernetes.io/docs for **"PVC Protection"** on the Persistent Volumes concept page. The
claim is held open by a finalizer while a Pod uses it - a deletion can't be cancelled, only
delayed. What happens to a dynamically provisioned PV when its claim finally goes, and which PV
field changes that?
