# q109-25: Two containers write to one claim without seeing each other's files

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-25-multi-container-shared-pvc-isolated-writes`

Catalyst Research Institute's sample-processing Pod needs two independent output areas, but a
namespace storage quota leaves it only one PersistentVolumeClaim to work with. Namespace
`q109-25-multi-container-shared-pvc-isolated-writes` already has that claim: `shared-multi`
(200Mi, `ReadWriteOnce`, dynamically provisioned from the cluster's default StorageClass).

Create a Pod named `partitioned` with two containers, both mounting `shared-multi` at `/data`,
but partition the claim so each container gets its own slice - `section-a` for one, `section-b`
for the other - so that neither ever sees the other's files there:

- container `writer-a`: image `busybox:1.36`, writes a file `a.txt` into `/data` and keeps
  running, using slice `section-a`
- container `writer-b`: image `busybox:1.36`, writes a file `b.txt` into `/data` and keeps
  running, using slice `section-b`

`ls /data` in `writer-a` must show exactly `a.txt`, and `ls /data` in `writer-b` must show
exactly `b.txt`.

## Hint

Search kubernetes.io/docs for **"Using subPath"** - the Volumes concept page shows how one
volume can be mounted more than once, each time pointing at a different sub-directory of the
same underlying storage.
