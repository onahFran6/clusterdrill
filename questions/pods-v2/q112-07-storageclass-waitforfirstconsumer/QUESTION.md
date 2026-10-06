# q112-07: The claim that waits for a Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-07-storageclass-waitforfirstconsumer`

A claim on the cluster's default storage can stay `Pending` for a reason that has nothing to do
with a broken provisioner.

- Create PVC `logs-pvc` (**200Mi**, `ReadWriteOnce`) using the cluster's **default** StorageClass -
  omit `storageClassName` entirely, since that is how you ask for the default.
- `(ungraded)` Before creating the Pod, check the PVC's phase and read why it's pending
  (`kubectl describe pvc`). Then find the default StorageClass's name and its volume binding mode
  (`kubectl get sc`).
- Create Pod `logger` (`busybox:1.36`) that appends the date to `/logs/run.log` every 5 seconds on
  that claim.

## Hint

Search kubernetes.io/docs for **"volumeBindingMode"** on the Storage Classes concept page. The
default class is marked in `kubectl get sc`'s output. If the mode is `WaitForFirstConsumer`, what
is it waiting for, and why would a scheduler-aware delay make sense for storage?
