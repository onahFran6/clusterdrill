# q109-15-pod-mounts-pvc-readonly: Mount an existing PersistentVolumeClaim read-only in a Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-15-pod-mounts-pvc-readonly`

`setup.sh` already created a bound PersistentVolume `readonly-pv` (hostPath `/tmp/ckad-readonly-pv`, `100Mi`, `ReadWriteOnce`, `storageClassName: ""`) and a PersistentVolumeClaim `readonly-claim` (`100Mi`, `ReadWriteOnce`, `storageClassName: ""`) bound to it, in namespace `q109-15-pod-mounts-pvc-readonly`.

It also created a Pod named `reader-app` (image `busybox:1.36`, command that sleeps for `3600` seconds) that does **not** mount the PVC yet.

Delete and recreate the Pod `reader-app` so that its container mounts PersistentVolumeClaim `readonly-claim` at path `/data`, **read-only**. Keep the image `busybox:1.36` and a command that sleeps for `3600` seconds.

## Hint

Search kubernetes.io/docs for **"readOnly volumeMounts persistentVolumeClaim"** - the Persistent Volumes concept page shows how to set `readOnly: true` on a Pod's `volumeMounts` entry so the container can read but not write to the mounted claim.
