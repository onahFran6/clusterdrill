# q109-45-statefulset-volumeclaimtemplates-storageclass-override: Pin a StatefulSet's volumeClaimTemplate to a non-default StorageClass

**Domain:** Application Design and Build · **Points:** 6 · **Namespace:** `q109-45-statefulset-volumeclaimtemplates-storageclass-override`

A StorageClass named `retained-storage` already exists (provisioner
`k8s.io/minikube-hostpath`, `reclaimPolicy: Retain`). It is not the cluster's default
StorageClass.

Create a StatefulSet named `ledger` with 2 replicas and `serviceName` set to `ledger` (a
headless Service is not required for grading). Each pod's container must be named `ledger`,
use image `busybox:1.36`, and run command `sleep 3600`.

Add a `volumeClaimTemplates` entry named `data` that:

- requests `100Mi` of storage with access mode `ReadWriteOnce`
- sets `storageClassName` to `retained-storage`
- is mounted at `/var/lib/ledger` in the container

## Hint

Search kubernetes.io/docs for **"StatefulSet volumeClaimTemplates"** - the StatefulSets concept
page shows `volumeClaimTemplates[].spec.storageClassName` accepting any StorageClass name, not
only the cluster's default. The default class on this cluster sets dynamically provisioned PVs
to `reclaimPolicy: Delete`; pinning the template to `retained-storage` keeps each replica's
data if the StatefulSet is deleted later.
