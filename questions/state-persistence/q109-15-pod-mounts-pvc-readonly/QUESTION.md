# q109-15-pod-mounts-pvc-readonly: Mount an existing PersistentVolumeClaim read-only in a Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-15-pod-mounts-pvc-readonly`

A bound PersistentVolume `readonly-pv` (hostPath `/tmp/ckad-readonly-pv`, `100Mi`,
`ReadWriteOnce`, `storageClassName: ""`) and a PersistentVolumeClaim `readonly-claim` (`100Mi`,
`ReadWriteOnce`, `storageClassName: ""`) already exist in namespace
`q109-15-pod-mounts-pvc-readonly`. The claim is bound to that volume.

A Pod named `reader-app` (image `busybox:1.36`, command that sleeps for `3600` seconds) is
already running and does **not** mount the PVC yet.

Delete and recreate Pod `reader-app` so its container mounts PersistentVolumeClaim
`readonly-claim` at path `/data`, **read-only** (`readOnly: true` on the volume mount). Keep
the image `busybox:1.36` and a command that sleeps for `3600` seconds.

## Hint

Search kubernetes.io/docs for **"readOnly volumeMounts persistentVolumeClaim"** - the Persistent
Volumes concept page shows how to set `readOnly: true` on a Pod's `volumeMounts` entry so the
container can read but not write to the mounted claim.
