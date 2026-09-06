# q109-19: Combine a Secret and downwardAPI data in one projected volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-19-projected-volume-secret-downwardapi`

`setup.sh` already created a Secret named `api-creds` with a key `token` containing `s3cr3t`, in
namespace `q109-19-projected-volume-secret-downwardapi`.

Create a Pod named `combo-app` (image `busybox:1.36`, command `sleep 3600`) with a single
**projected volume** named `combo`, mounted at `/etc/combo`, that combines two sources:

- The `api-creds` Secret's `token` key, projected to the path `secret-token`.
- A `downwardAPI` entry exposing the pod's own name (`fieldRef` on `metadata.name`), projected to
  the path `pod-name`.

When done, `/etc/combo/secret-token` must contain `s3cr3t` and `/etc/combo/pod-name` must contain
`combo-app` inside the running container.

## Hint

Search kubernetes.io/docs for **"projected volume"** - the Projected Volumes concept page shows an
example combining a `secret` source and a `downwardAPI` source under one `projected.sources` list,
each with its own `items[].path`.
