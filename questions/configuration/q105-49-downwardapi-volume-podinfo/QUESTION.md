# q105-49-downwardapi-volume-podinfo: Expose pod labels and annotations as files via a Downward API volume

**Domain:** Application Environment, Configuration and Security · **Points:** 6 · **Namespace:** `q105-49-downwardapi-volume-podinfo`

`setup.sh` has not created any pod for you in namespace `q105-49-downwardapi-volume-podinfo` -
author the manifest yourself.

Create a Pod named `metadata-exporter`, image `busybox:1.36`, container command `sleep 3600`,
with:

- pod labels `role=exporter` and `tier=backend`
- pod annotation `build.info/version=3.2.1`
- a `downwardAPI` **volume** (not environment variables) mounted at `/etc/podinfo`, exposing three
  files:
  - `pod-name` - the pod's own name (`fieldRef: metadata.name`)
  - `labels` - all of the pod's labels (`fieldRef: metadata.labels`)
  - `annotations` - all of the pod's annotations (`fieldRef: metadata.annotations`)

The pod must reach `Running`, and the three files must be readable inside the container with the
expected content.

## Hint

Search kubernetes.io/docs for **"downward api volume"** - the Expose Pod Information to
Containers task's "Store Pod Fields" example shows a `downwardAPI` volume's `items` list using
`fieldRef` to write `metadata.name`, `metadata.labels`, and `metadata.annotations` out as files.
