# q102-05: Shared emptyDir volume between containers

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-05-shared-emptydir-volume`

Create a Pod named `shared-vol-demo` with two containers that share data
through a single `emptyDir` volume named `shared`:

- `producer` (image `busybox:1.36`) - mounts the `shared` volume at
  `/producer-data` and continuously writes a line to
  `/producer-data/message.txt`.
- `consumer` (image `busybox:1.36`) - mounts the **same** `shared` volume,
  but at a **different** mount path, `/consumer-data`, and continuously
  reads/tails `/consumer-data/message.txt`.

Both containers must mount the volume named `shared` (what makes the data
shared is the volume **name** matching in both `volumeMounts`, not the mount
path - the two containers are deliberately given different paths).

## Hint

Search kubernetes.io/docs for **"emptyDir"** - the Volumes concept page's
`emptyDir` section shows how two containers in the same Pod can share files
through a common volume.
