# q107-22: Fix a sidecar log-shipper that reads the wrong file path from a shared volume

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-22-multi-container-shared-log-volume`

`setup.sh` already created a pod named `audit-logger` in namespace
`q107-22-multi-container-shared-log-volume` with two containers sharing an `emptyDir` volume
named `logs`:

- `writer` (image `busybox:1.36`) mounts the volume at `/var/log/app` and continuously appends
  the current date to `/var/log/app/audit.log`.
- `shipper` (image `busybox:1.36`) mounts the same volume at `/logs` and runs `tail -f
  /logs/access.log` - but `writer` never produces a file called `access.log`, only `audit.log`.
  As a result `shipper` immediately errors with `No such file or directory` and CrashLoopBackOffs.
  Confirm this with `kubectl logs audit-logger -n q107-22-multi-container-shared-log-volume -c
  shipper --previous`.

Fix the pod so `shipper` tails the file that `writer` actually produces. Change only the
`shipper` container's command to `sh -c 'tail -f /logs/audit.log'` (the correct filename, given
the two containers share the same volume, `writer`'s `/var/log/app` and `shipper`'s `/logs` are
the same directory). Do not change the `writer` container or either container's volume mounts.
The pod must end up `Running` with both containers `Ready`.

## Hint

Search kubernetes.io/docs for **"Communicate Between Containers in the Same Pod Using a Shared
Volume"** - the Configure a Pod to Use a Volume for Storage task shows how two containers mount
the same `emptyDir` at different paths and must agree on the filenames written there.
