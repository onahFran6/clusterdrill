# q109-25-multi-container-subpath-partitioned-pvc: Partition one PVC between two containers using different subPaths

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-25-multi-container-subpath-partitioned-pvc`

`setup.sh` created namespace `q109-25-multi-container-subpath-partitioned-pvc` with a
PersistentVolumeClaim named `shared-multi` (200Mi, `ReadWriteOnce`, dynamically provisioned
from the cluster's default StorageClass).

Create a Pod named `partitioned` with two containers that both mount the same `shared-multi`
PVC at `/data`, but each into a different partition of it via `subPath`, so neither container
can see the other's files:

- container `writer-a`: image `busybox:1.36`, command that runs
  `mkdir -p /data && echo a > /data/a.txt && sleep 3600`, mounting `shared-multi` at `/data`
  with `subPath: section-a`
- container `writer-b`: image `busybox:1.36`, command that runs
  `mkdir -p /data && echo b > /data/b.txt && sleep 3600`, mounting `shared-multi` at `/data`
  with `subPath: section-b`

The grader will exec `ls /data` in `writer-a` and expect exactly `a.txt` (not `b.txt`), and
exec `ls /data` in `writer-b` and expect exactly `b.txt` (not `a.txt`), proving the two
containers are isolated into separate subdirectories of the same underlying PVC.

## Hint

Search kubernetes.io/docs for **"Using subPath"** - the Volumes concept page shows how
`volumeMounts[].subPath` lets multiple containers share a single volume by mounting different
sub-paths of it, keeping each container's files isolated from the others.
