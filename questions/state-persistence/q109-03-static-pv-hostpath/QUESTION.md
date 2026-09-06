# q109-03: Statically provision a PersistentVolume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-03-static-pv-hostpath`

`setup.sh` created namespace `q109-03-static-pv-hostpath` but no resources yet. This cluster's
node has a directory `/mnt/q109-03-data` that a cluster administrator has set aside for a
statically-provisioned volume (no dynamic provisioner involved).

Create a PersistentVolume named `q109-03-data-pv` that:

- has capacity `1Gi`
- has access mode `ReadWriteOnce`
- uses `hostPath` pointing at `/mnt/q109-03-data`
- uses storage class name `manual`
- has reclaim policy `Retain`

A PersistentVolume is cluster-scoped, so it is not created inside the namespace above - but it
must still carry the same `clusterdrill-question` label as everything else in this task.

## Hint

Search kubernetes.io/docs for **"persistent volume hostPath example"** - the Persistent Volumes
concept page includes a full static PV manifest using `hostPath` you can adapt.
