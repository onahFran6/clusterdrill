# q102-12: Fix a broken multi-container Pod

**Domain:** Application Design and Build · **Points:** 10 · **Namespace:** `q102-12-broken-multicontainer-pod-fix`

A Pod named `broken-app` already exists in this namespace with two
containers, `writer` and `reader`, and two `emptyDir` volumes,
`cache-vol` and `empty-vol`. The `writer` container appends lines to
`/cache/data.txt` on `cache-vol`, but the `reader` container's
`volumeMounts` entry was copy/pasted with the wrong volume `name` - it
mounts `empty-vol` at `/cache` instead of `cache-vol`. Both names are
individually valid (so the Pod schedules and starts), but `reader` never
sees any of `writer`'s data because the two containers are no longer
sharing the same volume, and `reader`'s container keeps crash-looping
because the file it tails is never created on its own decoy volume.

Fix the Pod so that:

- It still has exactly 2 containers, named `writer` and `reader` (do not
  rename them or change their images).
- Every `volumeMounts[].name` used by `writer` and by `reader` refers to
  the shared `cache-vol` volume actually defined in `spec.volumes` (i.e.
  `reader` must mount `cache-vol`, not `empty-vol`, at `/cache`).

You cannot patch `volumeMounts` in place on a running Pod, so delete and
recreate `broken-app` with the corrected volume reference, keeping the
container names and images unchanged.

## Hint

Search kubernetes.io/docs for **"volumeMounts"** - the Volumes concept
page shows how each container's `volumeMounts[].name` must reference the
Pod-level `volumes[].name` it intends to share.
