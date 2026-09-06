# q109-32-emptydir-shared-initcontainer-writer: Hand data from an init container to the main container via emptyDir

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q109-32-emptydir-shared-initcontainer-writer`

Create a Pod named `config-fetcher` in namespace `q109-32-emptydir-shared-initcontainer-writer`
with:

- an init container named `fetch-config` (image `busybox:1.36`) that runs
  `sh -c "echo ready > /work/config.txt"`
- a main container named `app` (image `busybox:1.36`) that runs
  `sh -c "sleep 3600"`
- a shared `emptyDir` volume named `work`, mounted at `/work` in **both** containers, so the
  file the init container writes before it exits is still there for the main container to read
  once it starts

## Hint

Search kubernetes.io/docs for **"init containers" "shared volume"** - the Init Containers
concept page shows an init container and the Pod's app containers can share the same
`emptyDir` volume, letting an init container prepare files the main container reads once
running - the init container's own filesystem changes outside that shared volume do not
carry over.
