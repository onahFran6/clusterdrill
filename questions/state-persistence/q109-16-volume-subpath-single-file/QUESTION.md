# q109-16: Expose a single file from a PVC using subPath

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-16-volume-subpath-single-file`

`setup.sh` created namespace `q109-16-volume-subpath-single-file` with a PersistentVolumeClaim
named `shared-storage` (200Mi, `ReadWriteOnce`, dynamically provisioned from the cluster's
default StorageClass), already containing a file `app.conf` at its root with the contents
`ready=true`.

Create a Pod named `config-reader` that:

- uses image `busybox:1.36`
- runs the command `sleep 3600`
- mounts the `shared-storage` PVC using `subPath: app.conf`, so the container sees that
  single file directly at path `/etc/app.conf` (not a directory containing the file, and
  not the whole volume mounted at `/etc/app.conf`)

The grader will exec into `config-reader` and run `cat /etc/app.conf`, expecting exactly
`ready=true`, and will also confirm `/etc/app.conf` is a regular file rather than a directory.

## Hint

Search kubernetes.io/docs for **"Using subPath"** - the Volumes concept page shows how to use
`volumeMounts[].subPath` to mount a single file from a volume into a container without
exposing the rest of the volume's contents.
