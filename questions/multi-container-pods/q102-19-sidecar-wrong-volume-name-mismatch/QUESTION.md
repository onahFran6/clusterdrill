# q102-19-sidecar-wrong-volume-name-mismatch: Sidecar mounts wrong volume name, silently gets empty dir

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-19-sidecar-wrong-volume-name-mismatch`

A Pod named `metrics-pair` already exists in this namespace with two
containers, `writer` and `sidecar`, that are supposed to share one
`emptyDir` volume named `shared-data`. The `writer` container appends
metrics lines to `/var/writer/metrics.log` on `shared-data`, but whoever
wrote the `sidecar` container's `volumeMounts` entry typo'd the volume
name as `shared-dat` (missing the final `a`). The Pod's `spec.volumes`
list only defines `shared-data` (not `shared-dat`), so `sidecar`'s
container definition mounts a second, disconnected `emptyDir` at
`/var/sidecar` under the typo'd name - it never fails loudly, it just
silently gets its own empty directory instead of `writer`'s data, and
`sidecar` keeps crash-looping tailing a file that never appears on its
own decoy volume.

Fix the Pod so that:

- It still has exactly 2 containers, named `writer` and `sidecar` (do
  not rename them or change their images).
- `writer` mounts the shared volume at `/var/writer` and `sidecar`
  mounts the *same* shared volume at `/var/sidecar` - both
  `volumeMounts[].name` entries must reference the one `emptyDir`
  volume named `shared-data` defined in `spec.volumes` (i.e. `sidecar`
  must mount `shared-data`, not `shared-dat`).
- The Pod reaches `Running` with both containers ready (2/2).

You cannot patch `volumeMounts` in place on a running Pod, so delete
and recreate `metrics-pair` with the corrected volume reference,
keeping the container names, images, and mount paths unchanged.

## Hint

Search kubernetes.io/docs for **"volumeMounts"** - the Volumes concept
page shows how each container's `volumeMounts[].name` must reference
the Pod-level `volumes[].name` it intends to share.
