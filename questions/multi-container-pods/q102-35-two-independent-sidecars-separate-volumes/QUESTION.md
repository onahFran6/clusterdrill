# q102-35-two-independent-sidecars-separate-volumes: Two sidecars, two separate (unshared) volumes

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-35-two-independent-sidecars-separate-volumes`

Create a Pod named `scratch-pad` with three containers, all image
`busybox:1.36`, that idle forever (e.g. `sleep 3600` in a loop):

- `main` - no volume mounts at all.
- `cache-a` - mounts its own `emptyDir` volume named `cache-a-data` at
  `/cache`, and once at startup writes the file `/cache/owner.txt`
  containing exactly `cache-a`.
- `cache-b` - mounts a **different, separate** `emptyDir` volume named
  `cache-b-data`, also at `/cache`, and once at startup writes the file
  `/cache/owner.txt` containing exactly `cache-b`.

`cache-a` and `cache-b` must **not** share a volume - each has its own
independent `emptyDir`, so `cache-a`'s `/cache/owner.txt` and `cache-b`'s
`/cache/owner.txt` are two entirely separate files that happen to use the
same mount path and filename, each containing its own container's name (not
the other's).

## Hint

Search kubernetes.io/docs for **"emptyDir"** - the Volumes concept page
shows that a Pod's `volumes` list can declare more than one `emptyDir`, and
that two containers only actually share data when their `volumeMounts[]`
both reference the exact same volume `name` - otherwise each volume is its
own independent, per-container storage.
