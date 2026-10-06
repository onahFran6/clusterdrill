# q111-19: Pods stuck in Pending

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-19-pending-nodeselector-and-cpu`

Team Bacchus's `press` Deployment (seeded, 3 replicas) has all 3 pods Pending. The pods must run
only on nodes with fast disks, which the team marks with label `disktype=ssd`. No node has that
label yet.

- Read the scheduler's rejection message for one of the Pending pods - it lists every reason a
  node was rejected.
- Label a schedulable node as a fast-disk node.
- Fix `press` so each pod requests **250m** CPU, and all 3 pods run - still only on fast-disk
  nodes.

## Hint

Search kubernetes.io/docs for **"Assign Pods to Nodes"**. The pods already exist (unlike a
missing-ServiceAccount fault), so look at a later layer than admission: which component decides
*where* a pod runs, and where does it write its reasoning? `kubectl describe pod` on one of the
Pending pods lists every reason a node was rejected.
