# q109-02: Cap an in-memory emptyDir with a size limit

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-02-emptydir-sizelimit-memory`

`setup.sh` created namespace `q109-02-emptydir-sizelimit-memory` but no resources yet.

Create a Pod named `cache-pod` with a single container named `cache` (image `busybox:1.36`,
command that just sleeps forever) that has a volume named `fast-cache` mounted at `/cache`.
This volume must:

- back onto tmpfs (RAM) instead of the node's disk
- be capped so it can never grow past `64Mi`

## Hint

Search kubernetes.io/docs for **"emptyDir medium Memory sizeLimit"** - the Volumes concept
page's emptyDir section documents both the `medium` and `sizeLimit` fields together.
