# q102-08: Multiple init containers run in order

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-08-multiple-init-containers-order`

Create a Pod named `ordered-init-app` in this namespace with **two** init
containers, defined in this order, plus a main container:

1. `init-first` (image `busybox:1.36`) - creates the marker file
   `/work/first-done` in a shared `emptyDir` volume named `work-vol`, e.g.
   `sh -c "touch /work/first-done"`.
2. `init-second` (image `busybox:1.36`) - only succeeds if
   `/work/first-done` already exists, proving it ran *after* `init-first`,
   e.g. `sh -c "test -f /work/first-done && touch /work/second-done"`.

Then a main container named `main` (image `busybox:1.36`) that mounts the
same `work-vol` volume at `/work` and sleeps (e.g. `sleep 3600`).

Init containers run sequentially in the order they are listed under
`spec.initContainers`, and each must complete successfully before the next
one starts - `initContainers[0]` must be `init-first` and
`initContainers[1]` must be `init-second`.

## Hint

Search kubernetes.io/docs for **"init containers run sequentially"** - the
Init Containers concept page explains ordering guarantees when a Pod
specifies multiple init containers.
