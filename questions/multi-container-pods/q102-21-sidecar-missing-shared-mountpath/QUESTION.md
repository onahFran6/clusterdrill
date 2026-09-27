# q102-21: Let a sidecar see the shared audit log

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-21-sidecar-missing-shared-mountpath`

A Pod named `audit-logger` already exists in this namespace with two containers.
The main container `app` continuously appends timestamped lines to
`/var/log/audit/app.log`, backed by an `emptyDir` volume named `audit-vol`
mounted at `/var/log/audit`. The sidecar `shipper` is supposed to tail and
ship that same log file, but it never sees it - it loops printing
`waiting for file`.

Fix `shipper` so it can read the log: it must mount the existing `audit-vol`
volume at `/var/log/audit`. Do not change the `app` container, its volume, or
its mount.

The Pod must end up `Running` with both containers ready (2/2), and
`kubectl exec` into `shipper` must be able to `cat /var/log/audit/app.log`
successfully. Recreating the Pod is fine.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the Pods
concept page's "Communication between containers in the same Pod" section shows
how sidecars share a volume with the main container via matching
`volumeMounts` entries.
