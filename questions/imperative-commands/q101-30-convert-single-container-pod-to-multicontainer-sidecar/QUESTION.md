# q101-30-convert-single-container-pod-to-multicontainer-sidecar: Add a logging sidecar container to an existing single-container pod via generate-edit-apply

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-30-convert-single-container-pod-to-multicontainer-sidecar`

A Pod named `web-writer` is already running in namespace
`q101-30-convert-single-container-pod-to-multicontainer-sidecar` with a single container named
`main` (image `busybox:1.36`) that continuously appends timestamped lines to
`/var/log/app/output.log` on an `emptyDir` volume named `log-vol`, already mounted at
`/var/log/app`.

Add a second container named `log-shipper` (image `busybox:1.36`) to the **same** running Pod that
tails `/var/log/app/output.log` to its own stdout, so `kubectl logs web-writer -c log-shipper`
shows the same log lines `main` is writing. `log-shipper` must mount the same `log-vol` volume at
`/var/log/app`.

You cannot add a new container to a running Pod with `kubectl patch` alone - a Pod's
`spec.containers` list cannot add or remove entries in place on a live object. Export the live Pod
spec, strip the fields the API server owns (`status`, `metadata.uid`, `resourceVersion`,
`creationTimestamp`, managed fields, the auto-assigned `nodeName`, etc.), add the `log-shipper`
container to `spec.containers`, delete the old Pod, then re-apply the edited manifest - keeping the
Pod named exactly `web-writer` and leaving the original `main` container's spec (image, command,
volume mount) untouched.

When you are done, `web-writer` must have exactly two containers - `main` and `log-shipper` - both
with `log-vol` mounted at `/var/log/app`, and `log-shipper`'s logs must contain lines matching
`main`'s output.

## Hint

Search kubernetes.io/docs for **"communicate containers same pod shared volume"** - the "Configure
a Pod to Use a Volume" task page shows two containers in one Pod sharing an `emptyDir` this exact
way.
