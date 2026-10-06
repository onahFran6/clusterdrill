# q112-05: Shared memory-backed cache

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-05-shared-memory-cache`

Two containers in one Pod need to share a fast scratch area that lives entirely in RAM. Build
this Pod from scratch.

- Create Pod `cache-pair` with containers `writer` and `reader`, both `busybox:1.36`.
- `writer` writes the current date to `/cache/now` every 2 seconds. `reader` prints that file
  every 5 seconds.
- The shared volume must be memory-backed and capped at **64Mi**.

## Hint

Search kubernetes.io/docs for **"emptyDir"** in the Volumes concept page. An `emptyDir` has an
optional field for its backing medium and another for its size limit. `mount` inside a container
shows the filesystem type for a given mount point - a memory-backed `emptyDir` reports a
different type than a normal one.
