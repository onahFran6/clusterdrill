# q109-03: Statically provision a PersistentVolume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-03-static-pv-hostpath`

This cluster's node has a directory `/mnt/q109-03-data` set aside for a statically-provisioned
volume.

Create a PersistentVolume named `q109-03-data-pv` that:

- has capacity `1Gi`
- has access mode `ReadWriteOnce`
- uses `hostPath` pointing at `/mnt/q109-03-data`
- uses storage class name `manual`
- has reclaim policy `Retain`
- carries label `clusterdrill-question=q109-03-static-pv-hostpath`

## Hint

Search kubernetes.io/docs for **"persistent volume hostPath example"** - the Persistent Volumes
concept page includes a full static PV manifest using `hostPath` you can adapt. A
PersistentVolume is cluster-scoped, so it is not created inside the question namespace. No
dynamic provisioner is involved for this volume.
