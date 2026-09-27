# q109-25-multi-container-subpath-partitioned-pvc: Partition one PVC between two containers using different subPaths

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-25-multi-container-subpath-partitioned-pvc`

Namespace `q109-25-multi-container-subpath-partitioned-pvc` already has a PersistentVolumeClaim
named `shared-multi` (200Mi, `ReadWriteOnce`, dynamically provisioned from the cluster's default
StorageClass).

Create a Pod named `partitioned` with two containers that both mount the same `shared-multi`
PVC at `/data`, each with a different `subPath`:

- container `writer-a`: image `busybox:1.36`, command that runs
  `mkdir -p /data && echo a > /data/a.txt && sleep 3600`, mounting `shared-multi` at `/data`
  with `subPath: section-a`
- container `writer-b`: image `busybox:1.36`, command that runs
  `mkdir -p /data && echo b > /data/b.txt && sleep 3600`, mounting `shared-multi` at `/data`
  with `subPath: section-b`

`ls /data` in `writer-a` must show exactly `a.txt`, and `ls /data` in `writer-b` must show
exactly `b.txt`.

## Hint

Search kubernetes.io/docs for **"Using subPath"** - the Volumes concept page shows how
`volumeMounts[].subPath` lets multiple containers share a single volume by mounting different
sub-paths of it, so neither container sees the other's files.
