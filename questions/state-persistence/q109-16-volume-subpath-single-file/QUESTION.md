# q109-16: Expose a single file from a PVC using subPath

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-16-volume-subpath-single-file`

Namespace `q109-16-volume-subpath-single-file` already has a PersistentVolumeClaim named
`shared-storage` (200Mi, `ReadWriteOnce`, dynamically provisioned from the cluster's default
StorageClass). The volume already contains a file `app.conf` at its root with the contents
`ready=true`.

Create a Pod named `config-reader` that:

- uses image `busybox:1.36`
- runs the command `sleep 3600`
- mounts the `shared-storage` PVC using `subPath: app.conf`, so the container sees that single
  file at path `/etc/app.conf`

Inside `config-reader`, `cat /etc/app.conf` must print exactly `ready=true`, and `/etc/app.conf`
must be a regular file rather than a directory.

## Hint

Search kubernetes.io/docs for **"Using subPath"** - the Volumes concept page shows how to use
`volumeMounts[].subPath` to mount a single file from a volume into a container without exposing
the rest of the volume's contents. Do not mount the whole volume at `/etc/app.conf`, and do not
mount a directory that merely contains the file.
