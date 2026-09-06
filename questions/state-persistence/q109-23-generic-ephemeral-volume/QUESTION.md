# q109-23: Give a Pod its own generic ephemeral volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-23-generic-ephemeral-volume`

Create a Pod named `ephemeral-app` with a single container named `ephemeral-app` (image
`busybox:1.36`, command that sleeps for 3600 seconds) that has a **generic ephemeral volume**
named `scratch`: an inline `volumeClaimTemplate` requesting `50Mi` of `ReadWriteOnce` storage
(using the cluster's default StorageClass). Mount that volume in the container at `/scratch`.

Kubernetes will auto-create a PersistentVolumeClaim named `ephemeral-app-scratch` for this
volume - do not create the PVC yourself.

## Hint

Search kubernetes.io/docs for **"generic ephemeral volumes"** - the Ephemeral Volumes concept
page shows the exact `volumes` entry with an inline `ephemeral.volumeClaimTemplate` field, and
explains the `<pod name>-<volume name>` PVC naming convention.
