# q102-19: Fix a sidecar that never sees shared metrics

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-19-sidecar-wrong-volume-name-mismatch`

A Pod named `metrics-pair` has two containers, `writer` and `sidecar`, that
are supposed to share the `emptyDir` volume `shared-data` - `writer` appends
metrics to `/var/writer/metrics.log` on that volume, and `sidecar` is meant to
tail the same file from `/var/sidecar`. `sidecar` keeps crash-looping: it never
sees any of `writer`'s output.

Fix the Pod so both containers mount the same `shared-data` volume, `writer`
at `/var/writer` and `sidecar` at `/var/sidecar`, and the Pod reaches `Running`
with both containers ready (2/2). Keep both container names, images, and mount
paths unchanged; recreating the Pod is fine.

Verify with `kubectl exec metrics-pair -c sidecar -- cat /var/sidecar/metrics.log`
- it should show `writer`'s output, not an empty file.

## Hint

Search kubernetes.io/docs for **"volumeMounts"** - the Volumes concept
page shows how each container's `volumeMounts[].name` must reference
the Pod-level `volumes[].name` it intends to share.
