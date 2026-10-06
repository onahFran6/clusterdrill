# q114-14: A claim for every replica

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-14-a-claim-for-every-replica`

A key-value store needs each replica to keep its **own** data across restarts.

- Create headless Service `kv` (`clusterIP: None`) and StatefulSet `kv` (2 replicas,
  `busybox:1.36`, one `volumeClaimTemplates` entry named `data`, 100Mi, default StorageClass)
  where each replica writes its own hostname to `/data/id` once, if missing.
- Delete pod `kv-0` and confirm it comes back with the **same** `/data/id` content.
- Scale to 1 replica and confirm **both** `data-kv-0` and `data-kv-1` claims still exist even
  though only one pod is running.

## Hint

Search kubernetes.io/docs for **"StatefulSet volumeClaimTemplates"** - each replica gets its own
PersistentVolumeClaim, named `<volumeClaimTemplate-name>-<pod-name>`. Predict first: does scaling
down a StatefulSet delete its claims?
