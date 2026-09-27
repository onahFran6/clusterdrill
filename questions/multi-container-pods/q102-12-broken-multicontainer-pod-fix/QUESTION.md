# q102-12: Fix a broken multi-container Pod

**Domain:** Application Design and Build · **Points:** 10 · **Namespace:** `q102-12-broken-multicontainer-pod-fix`

A Pod named `broken-app` already exists in this namespace with two containers,
`writer` and `reader`, that are supposed to share an `emptyDir` volume named
`cache-vol`. `writer` appends lines to `/cache/data.txt` on that volume, but
`reader` never sees any of `writer`'s data and keeps crash-looping while
waiting for a file that never appears on its mount.

Fix the Pod so that:

- It still has exactly 2 containers, named `writer` and `reader` (do not
  rename them or change their images).
- Both containers mount the shared `cache-vol` volume - `writer` and `reader`
  must each reference `cache-vol` at `/cache`.
- The Pod reaches `Running` with both containers ready.

You cannot patch `volumeMounts` in place on a running Pod, so delete and
recreate `broken-app` with the corrected volume reference, keeping the
container names and images unchanged.

## Hint

Search kubernetes.io/docs for **"volumeMounts"** - the Volumes concept
page shows how each container's `volumeMounts[].name` must reference the
Pod-level `volumes[].name` it intends to share. Compare each container's
mounts against the Pod's `volumes` list.
