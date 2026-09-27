# q109-01: Add scratch space to a container with emptyDir

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-01-emptydir-basic-scratch`

Create a Pod named `render-worker` with a single container named `worker` (image
`busybox:1.36`, command that sleeps forever) and:

- a volume named `scratch` of type `emptyDir`
- the `worker` container mounting that volume at `/var/scratch`

## Hint

Search kubernetes.io/docs for **"emptyDir"** - the Volumes concept page shows the exact
`volumes` and `volumeMounts` fields an emptyDir needs, with a copy-paste example. That volume
lasts for the Pod's lifetime, including container restarts, and is removed when the Pod is
deleted.
