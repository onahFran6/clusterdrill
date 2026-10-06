# q114-17: Permission denied on the volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-17-permission-denied-on-the-volume`

Deployment `uploader` runs as user 1000 for security and crashes writing to `/data`, which comes
from claim `uploads` on a `hostPath` PV.

- `(ungraded)` Read the error from the crashed container's previous logs.
- Fix it **without** adding `runAsUser`/running the main container as root. Add an init container
  (itself running as root) that `chown`s `/data` to `1000:2000` before the app starts.

## Hint

Search kubernetes.io/docs for **"fsGroup"** on the Pod Security Context page. `fsGroup` is
already set at the pod level, yet writing still fails - not every volume type gets its ownership
managed by the kubelet, and `hostPath` is one that doesn't. Something that runs *before* the app,
as root, could fix the ownership once.
