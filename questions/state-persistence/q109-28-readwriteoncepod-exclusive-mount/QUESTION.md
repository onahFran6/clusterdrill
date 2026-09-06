# q109-28-readwriteoncepod-exclusive-mount: Restrict a volume to a single Pod with ReadWriteOncePod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-28-readwriteoncepod-exclusive-mount`

Create a statically-provisioned PersistentVolume named `exclusive-pv` that:

- has capacity `50Mi`
- uses `hostPath` pointing at `/tmp/ckad-exclusive-pv`
- has access mode `ReadWriteOncePod` (and only that access mode)
- uses storage class name `""` (empty string, no dynamic provisioner)

Create a PersistentVolumeClaim named `exclusive-claim` in namespace
`q109-28-readwriteoncepod-exclusive-mount` that:

- requests `50Mi`
- has access mode `ReadWriteOncePod` (and only that access mode)
- uses storage class name `""` (empty string) so it binds to `exclusive-pv` instead of
  triggering dynamic provisioning

It must end up `Bound` to `exclusive-pv`.

Create a Pod named `owner-pod` in the same namespace with a single container named `owner`
(image `busybox:1.36`, command that sleeps for 3600 seconds) that mounts `exclusive-claim` at
`/data`. The Pod must reach `Running`.

`ReadWriteOncePod` (unlike `ReadWriteOnce`) guarantees the volume can be mounted read-write by
at most one Pod in the whole cluster at a time, not just one node - only one Pod can ever hold
this claim's exclusive lock.

## Hint

Search kubernetes.io/docs for **"ReadWriteOncePod"** - the Persistent Volumes concept page's
access modes table explains how `ReadWriteOncePod` differs from `ReadWriteOnce` and how to
request it on both the PV and the PVC.
