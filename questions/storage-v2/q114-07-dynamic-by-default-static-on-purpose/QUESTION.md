# q114-07: Dynamic by default, static on purpose

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-07-dynamic-by-default-static-on-purpose`

A static PV `q114-07-static-pv` (1Gi, `ReadWriteOnce`) already exists with **no** StorageClass,
reserved for this namespace's own use.

- Create PVC `dyn` (200Mi, `ReadWriteOnce`) that gets a **new** volume from the cluster's default
  StorageClass - omit `storageClassName` entirely.
- Create PVC `stat` (1Gi, `ReadWriteOnce`, `storageClassName: ""`) that binds to the pre-existing
  static PV and must never trigger provisioning.
- Use both claims from one Pod `seine-app` (`busybox:1.36`).

## Hint

Search kubernetes.io/docs for **"Persistent Volumes"**, the "Class" section. Leaving
`storageClassName` out and setting it to `""` look similar but mean opposite things - which one
gets the default class filled in, and which one means "no class, ever"?
