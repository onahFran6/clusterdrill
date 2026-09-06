# q102-11: Init container fixes volume permissions

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-11-init-container-permission-fix`

Create a Pod named `secure-app` with a shared `emptyDir` volume named
`data-vol` and two containers:

- An **init container** named `fix-permissions` (image `busybox:1.36`) that
  mounts `data-vol` at `/data` and, running as the default root user, fixes
  ownership and permissions on the volume so a non-root user can write to
  it - e.g. `sh -c "chown -R 1000:1000 /data && chmod -R 755 /data"`.
- A main container named `main` (image `busybox:1.36`) that also mounts
  `data-vol` at `/data`, runs as UID `1000` via
  `securityContext.runAsUser: 1000`, and runs a command that writes into the
  volume, e.g. `sh -c "touch /data/test.txt && sleep 3600"`.

Without the init container's ownership fix, the non-root main container
would fail to write to the (root-owned by default) `emptyDir`.

## Hint

Search kubernetes.io/docs for **"init containers"** - the Workloads / Pods
page's "Init Containers" section explains using an init container to adjust
shared volume permissions before a non-root application container starts.
