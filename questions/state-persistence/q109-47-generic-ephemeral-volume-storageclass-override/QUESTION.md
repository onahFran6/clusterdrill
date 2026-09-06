# q109-47-generic-ephemeral-volume-storageclass-override: Pin a generic ephemeral volume to a non-default StorageClass

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-47-generic-ephemeral-volume-storageclass-override`

`setup.sh` already created a StorageClass named `fast-scratch` in this cluster (provisioner
`k8s.io/minikube-hostpath`, `volumeBindingMode: Immediate`) - **not** the cluster's built-in
default StorageClass.

Create a Pod named `benchmark-runner` with a single container named `benchmark-runner` (image
`busybox:1.36`, command that sleeps for 3600 seconds) that has a **generic ephemeral volume**
named `scratch`: an inline `volumeClaimTemplate` requesting `256Mi` of `ReadWriteOnce` storage,
with `storageClassName` explicitly set to `fast-scratch` (not the cluster default). Mount that
volume in the container at `/scratch`.

Kubernetes will auto-create a PersistentVolumeClaim named `benchmark-runner-scratch` for this
volume, provisioned through `fast-scratch` - do not create the PVC yourself.

## Hint

Search kubernetes.io/docs for **"generic ephemeral volumes"** - the Ephemeral Volumes concept
page shows the inline `ephemeral.volumeClaimTemplate.spec` accepting the same fields as a normal
PVC spec, including `storageClassName`, letting a generic ephemeral volume opt into a specific
StorageClass instead of always using the cluster's default.
