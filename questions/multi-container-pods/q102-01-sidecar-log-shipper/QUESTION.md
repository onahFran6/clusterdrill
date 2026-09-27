# q102-01: Sidecar log shipper

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-01-sidecar-log-shipper`

A Pod named `writer-app` already exists in this namespace with a single container
named `writer` (image `busybox:1.36`) that continuously appends timestamped lines
to `/var/log/app/output.log`. The volume backing `/var/log/app` is an `emptyDir`
named `log-data`.

Add a second container named `log-shipper` (image `busybox:1.36`) that mounts the
same `log-data` volume at `/var/log/app` (read-only is fine) and runs
`tail -f /var/log/app/output.log` so it streams the writer's log lines. You cannot
add a container to a running Pod in place - delete and recreate `writer-app` with
both containers defined from the start, keeping `writer`'s image, volume, and
command unchanged.

The Pod must end up with exactly two containers: `writer` and `log-shipper`, both
mounting `log-data` at `/var/log/app`.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the Pods
concept page's "Communication between containers in the same Pod" section shows
the shared-volume sidecar example this task is based on.
