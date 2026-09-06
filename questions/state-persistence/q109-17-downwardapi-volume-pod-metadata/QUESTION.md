# q109-17: Expose Pod metadata as files with a downwardAPI volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-17-downwardapi-volume-pod-metadata`

Create a Pod named `self-aware` with a single container named `self-aware` (image `busybox:1.36`,
command that sleeps for 3600 seconds) and labels `app=self-aware` and `tier=frontend`.

Add a `downwardAPI` volume named `podinfo` mounted at `/etc/podinfo`, exposing:

- the Pod's `metadata.name` as file `podname`
- the Pod's `metadata.labels` as file `labels`

## Hint

Search kubernetes.io/docs for **"downwardAPI volume fieldRef"** - the Expose Pod Information to
Containers Through Files task shows how to project `metadata.name` and `metadata.labels` into
files inside a volume.
