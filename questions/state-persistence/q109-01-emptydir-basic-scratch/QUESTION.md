# q109-01: Add scratch space to a container with emptyDir

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-01-emptydir-basic-scratch`

`setup.sh` created namespace `q109-01-emptydir-basic-scratch` but no resources yet.

Create a Pod named `render-worker` with a single container named `worker` (image
`busybox:1.36`, command that sleeps forever) that has scratch space that survives container
restarts within the pod's lifetime but does not need to survive the pod being deleted. Give it:

- a volume named `scratch` of type `emptyDir`
- the `worker` container mounting that volume at `/var/scratch`

## Hint

Search kubernetes.io/docs for **"emptyDir"** - the Volumes concept page shows the exact
`volumes` and `volumeMounts` fields an emptyDir needs, with a copy-paste example.
