# q102-21-sidecar-missing-shared-mountpath: Sidecar container missing volumeMount entirely

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-21-sidecar-missing-shared-mountpath`

A pod named `audit-logger` already exists in this namespace with two containers.
The main container `app` continuously appends timestamped lines to
`/var/log/audit/app.log`, backed by an `emptyDir` volume named `audit-vol` that
is correctly mounted at `/var/log/audit`. The sidecar container `shipper` is
supposed to tail and "ship" that same log file, but its `volumeMounts` section
is missing entirely - it never sees the log file, so it just loops printing
`waiting for file`.

Fix the `shipper` container so it can see the log file: add a `volumeMount` to
`shipper` referencing the existing `audit-vol` volume at mountPath
`/var/log/audit`. Do not change the `app` container, its volume, or its mount.

The pod must end up `Running` with both containers ready (2/2), and
`kubectl exec` into `shipper` must be able to `cat /var/log/audit/app.log`
successfully.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the Pods
concept page's "Communication between containers in the same Pod" section shows
how sidecars share a volume with the main container via matching
`volumeMounts` entries.
