# q107-26-node-pressure-eviction-diagnosis: Diagnose an Evicted pod caused by node DiskPressure and reschedule it with an emptyDir size limit

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-26-node-pressure-eviction-diagnosis`

A pod named `log-spooler` (image `busybox:1.36`) already exists in namespace
`q107-26-node-pressure-eviction-diagnosis`. It has been evicted. It wrote into an `emptyDir`
volume named `scratch` mounted at `/scratch`.

Replace it:

- confirm with `kubectl get` and `kubectl describe` that `log-spooler` is `Evicted` and why
- delete the evicted pod
- recreate a pod, also named `log-spooler`, in the same namespace, with image `busybox:1.36`,
  command `sh -c 'sleep 3600'`, and a volume named `scratch` mounted at `/scratch` as an
  `emptyDir` with `sizeLimit: 500Mi`
- do not re-run the disk-filling command
- the pod reaches and stays `Running`

## Hint

Search kubernetes.io/docs for **"emptyDir sizeLimit"** - the "Configure a Pod to Use a Volume for
Storage" and "Node-pressure Eviction" pages both cover how an `emptyDir`'s `sizeLimit` field caps
local ephemeral storage per-volume, independent of node-level DiskPressure. The original command
wrote an 800Mi file into `scratch` and the node evicted the pod for ephemeral-storage pressure.
Repeating that fill against a 500Mi `sizeLimit` would kill the container again; this task only
needs the guard in place and the pod `Running`.
