# q114-01: Pick the fast volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-01-pick-the-fast-volume`

The storage admin already created two identical 1Gi PersistentVolumes in StorageClass
`manual-q114-01`: `q114-01-fast-pv` (label `tier=fast`) and `q114-01-slow-pv` (label `tier=slow`).

- Create PVC `nile-data` (1Gi, `ReadWriteOnce`, StorageClass `manual-q114-01`) that can only bind
  to the **fast** volume via a label selector. Don't name the PV directly in the claim.
- Create Pod `nile-app` (`busybox:1.36`) that mounts the claim at `/data` and writes `hello nile`
  to `/data/msg`.

## Hint

Search kubernetes.io/docs for **"Persistent Volumes"**, the "Selector" field under
`PersistentVolumeClaimSpec`. A claim can filter candidate PVs by label, the same way a Deployment
selects pods - size, class and access mode alone can't tell these two PVs apart.
