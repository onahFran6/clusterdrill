# q109-36-fix-hostpath-type-mismatch: Fix a hostPath volume whose declared type doesn't match reality

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-36-fix-hostpath-type-mismatch`

A directory already exists on the node at `/mnt/q109-36-logs`. A Pod named `log-writer` in
namespace `q109-36-fix-hostpath-type-mismatch` mounts that path as a `hostPath` volume at
`/var/log/app`, but the container never starts.

Recreate `log-writer` so `hostPath.type` is `Directory`. Keep `hostPath.path`
(`/mnt/q109-36-logs`) and the mount path (`/var/log/app`).

## Hint

Search kubernetes.io/docs for **"hostPath volume types"** - the Volumes concept page's
hostPath section lists the values `hostPath.type` accepts (`Directory`, `File`,
`DirectoryOrCreate`, `FileOrCreate`, and others). The kubelet checks the path against the
requested type before mounting and fails the mount with `FailedMount` when they differ.
`hostPath.type` cannot be patched on a running Pod. The path on this node is a directory,
and the Pod's current type is not `Directory`.
