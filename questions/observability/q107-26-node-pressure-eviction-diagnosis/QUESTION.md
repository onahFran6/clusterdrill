# q107-26-node-pressure-eviction-diagnosis: Diagnose an Evicted pod caused by node DiskPressure and reschedule it with an emptyDir size limit

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-26-node-pressure-eviction-diagnosis`

`setup.sh` already created a pod named `log-spooler` (image `busybox:1.36`) in namespace
`q107-26-node-pressure-eviction-diagnosis`. It writes an 800Mi file into an `emptyDir` volume
named `scratch` mounted at `/scratch`. The pod has since been evicted by the node: its status
shows `Evicted`, and the eviction message points at ephemeral-storage pressure.

Investigate and fix it:

- Run `kubectl get pod log-spooler -n q107-26-node-pressure-eviction-diagnosis` and
  `kubectl describe pod log-spooler -n q107-26-node-pressure-eviction-diagnosis` to confirm the
  pod was `Evicted` and read why.
- Delete the evicted `log-spooler` pod.
- Recreate a pod, also named `log-spooler`, in the same namespace, with:
  - the same image `busybox:1.36`
  - command `sh -c 'sleep 3600'` (do **not** re-run the 800Mi `dd` fill - it would immediately
    hit the new guard below and get the container evicted/killed again, which defeats the point
    of this exercise: you only need the guard in place and the pod `Running`, not to re-trigger
    the failure)
  - a volume named `scratch` mounted at `/scratch`, but this time as an `emptyDir` with
    `sizeLimit: 500Mi` set, so that a *future* 800Mi fill would hit the volume's own size limit
    fast, instead of the node running low on disk the way the original pod did.
  - the pod reaches and stays `Running`

## Hint

Search kubernetes.io/docs for **"emptyDir sizeLimit"** - the "Configure a Pod to Use a Volume for
Storage" and "Node-pressure Eviction" pages both cover how an `emptyDir`'s `sizeLimit` field caps
local ephemeral storage per-volume, independent of node-level DiskPressure.
