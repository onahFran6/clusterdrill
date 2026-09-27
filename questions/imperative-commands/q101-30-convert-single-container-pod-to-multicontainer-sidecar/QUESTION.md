# q101-30: Add a logging sidecar to a running Pod

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-30-convert-single-container-pod-to-multicontainer-sidecar`

A Pod named `web-writer` is already running in namespace
`q101-30-convert-single-container-pod-to-multicontainer-sidecar` with a single container named
`main` (image `busybox:1.36`) that continuously appends timestamped lines to
`/var/log/app/output.log` on an `emptyDir` volume named `log-vol`, mounted at `/var/log/app`.

Add a second container named `log-shipper` (image `busybox:1.36`) to the same Pod that tails
`/var/log/app/output.log` to stdout, so `kubectl logs web-writer -c log-shipper` shows the lines
`main` is writing. `log-shipper` must mount the same `log-vol` volume at `/var/log/app`.

Export the live Pod, edit in the new container, delete the old Pod, and re-apply - keeping the
Pod named exactly `web-writer` and leaving the original `main` container's image, command, and
volume mount untouched.

When you are done, `web-writer` must have exactly two containers - `main` and `log-shipper` -
both with `log-vol` mounted at `/var/log/app`, and `log-shipper`'s logs must contain lines matching
`main`'s output.

## Hint

Search kubernetes.io/docs for **"communicate containers same pod shared volume"** - the "Configure
a Pod to Use a Volume" task page shows two containers in one Pod sharing an `emptyDir` this exact
way.
