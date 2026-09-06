# q109-36-fix-hostpath-type-mismatch: Fix a hostPath volume whose declared type doesn't match reality

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-36-fix-hostpath-type-mismatch`

`setup.sh` already created, on the node, a real directory at `/mnt/q109-36-logs` (not a file),
and a Pod named `log-writer` in namespace `q109-36-fix-hostpath-type-mismatch` mounting that
path as a `hostPath` volume at `/var/log/app` - but the volume's `hostPath.type` is set to
`File`, not `Directory`. Kubernetes checks a hostPath volume's type against what is actually on
the node before starting the container, so `log-writer`'s container never starts: it fails with
a `FailedMount` event because `/mnt/q109-36-logs` is a directory, not a file.

Fix the Pod's `hostPath.type` to `Directory` so the container can actually start.
`hostPath.type` cannot be patched on a running Pod - delete and recreate `log-writer` with the
corrected type, keeping the same `hostPath.path` (`/mnt/q109-36-logs`) and mount path
(`/var/log/app`).

## Hint

Search kubernetes.io/docs for **"hostPath volume types"** - the Volumes concept page's
hostPath section lists the values `hostPath.type` accepts (`Directory`, `File`,
`DirectoryOrCreate`, `FileOrCreate`, and others) and states that the kubelet checks the path
against the requested type before mounting, failing the mount if they don't match.
