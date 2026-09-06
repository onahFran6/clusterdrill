# q109-21: Give each StatefulSet replica its own PVC via volumeClaimTemplates

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-21-statefulset-volumeclaimtemplates`

Create a StatefulSet named `db` with 2 replicas and `serviceName` set to `db` (a headless
Service is not required for grading). Each pod's container must be named `db`, use image
`busybox:1.36`, and run command `sleep 3600`.

Add a `volumeClaimTemplates` entry named `data` that requests `100Mi` of storage with access
mode `ReadWriteOnce` (use the cluster's default StorageClass), and mount it at `/var/lib/data`
in the container.

## Hint

Search kubernetes.io/docs for **"StatefulSet volumeClaimTemplates"** - the StatefulSets concept
page shows how each replica gets its own PersistentVolumeClaim, named
`<volumeClaimTemplate-name>-<pod-name>`.
