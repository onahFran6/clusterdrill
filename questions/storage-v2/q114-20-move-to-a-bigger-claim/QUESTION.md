# q114-20: Move to a bigger claim

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-20-move-to-a-bigger-claim`

Deployment `archive` keeps its files on claim `old-data` (100Mi). It's full, and this cluster
can't expand claims (see q114-08).

- Create PVC `new-data` (500Mi, default StorageClass).
- Scale `archive` to 0 so the `ReadWriteOnce` claim frees up. Copy everything from `old-data` to
  `new-data` using a temporary Pod `mover`.
- Switch `archive`'s volume to `new-data` and scale back to 1.

## Hint

Search kubernetes.io/docs for **"Persistent Volumes"**, the "Resizing" limitations note. Stop the
writer by scaling to 0 first, so the data is consistent and the RWO claim is actually free. The
mover Pod mounts both claims at once. `cp -a` keeps ownership and timestamps. Switching the claim
name is one field in the pod template.
