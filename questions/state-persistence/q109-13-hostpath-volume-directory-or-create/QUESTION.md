# q109-13: Mount a raw hostPath volume with type DirectoryOrCreate

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-13-hostpath-volume-directory-or-create`

Create a Pod named `log-writer` in this namespace that runs image `busybox:1.36` with
command `["sh", "-c", "sleep 3600"]` so it stays running.

Give the Pod a `hostPath` volume named `hostlogs` that points at path `/tmp/ckad-hostlogs`
on the node, using type `DirectoryOrCreate` (so Kubernetes creates the directory on the
node if it does not already exist). Mount that volume in the container at `/var/log/app`.

## Hint

Search kubernetes.io/docs for **"hostPath DirectoryOrCreate"** - the Volumes concept page's
hostPath section lists every `type` value a hostPath volume can use, including
`DirectoryOrCreate`.
