# q109-45-statefulset-volumeclaimtemplates-storageclass-override: Pin a StatefulSet's volumeClaimTemplate to a non-default StorageClass

**Domain:** Application Design and Build · **Points:** 6 · **Namespace:** `q109-45-statefulset-volumeclaimtemplates-storageclass-override`

`setup.sh` already created a StorageClass named `retained-storage` in this cluster
(provisioner `k8s.io/minikube-hostpath`, `reclaimPolicy: Retain`) - **not** the cluster's
built-in default StorageClass, which defaults every dynamically-provisioned PV to
`reclaimPolicy: Delete`.

Create a StatefulSet named `ledger` with 2 replicas and `serviceName` set to `ledger` (a
headless Service is not required for grading). Each pod's container must be named `ledger`,
use image `busybox:1.36`, and run command `sleep 3600`.

Add a `volumeClaimTemplates` entry named `data` that:

- requests `100Mi` of storage with access mode `ReadWriteOnce`
- explicitly sets `storageClassName` to `retained-storage` (**not** the cluster's default -
  every replica's PVC must be provisioned through this specific class, so its data survives
  even if the StatefulSet itself is deleted later)
- is mounted at `/var/lib/ledger` in the container

## Hint

Search kubernetes.io/docs for **"StatefulSet volumeClaimTemplates"** - the StatefulSets concept
page shows `volumeClaimTemplates[].spec.storageClassName` accepting any StorageClass name, not
only the cluster's default, letting a StatefulSet pin its replicas' storage to a specific class
with the reclaim/binding behavior the workload actually needs.
