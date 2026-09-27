# q107-22: Fix a sidecar log-shipper that reads the wrong file path from a shared volume

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-22-multi-container-shared-log-volume`

A pod named `audit-logger` already exists in namespace `q107-22-multi-container-shared-log-volume`
with two containers sharing an `emptyDir` volume named `logs`:

- `writer` (image `busybox:1.36`) mounts the volume at `/var/log/app` and appends to
  `/var/log/app/audit.log`
- `shipper` (image `busybox:1.36`) mounts the same volume at `/logs` and is not Ready

Change only the `shipper` container's command to `sh -c 'tail -f /logs/audit.log'`. Do not change
the `writer` container or either container's volume mounts. Both containers must be `Ready`.

## Hint

Search kubernetes.io/docs for **"Communicate Between Containers in the Same Pod Using a Shared
Volume"** - the Configure a Pod to Use a Volume for Storage task shows how two containers mount
the same `emptyDir` at different paths and must agree on the filenames written there. `shipper`
currently runs `tail -f /logs/access.log`, but `writer` only creates `audit.log`. The two mount
paths are the same directory, so `shipper` errors with `No such file or directory` and
CrashLoopBackOffs. `kubectl logs audit-logger -c shipper --previous` shows that.
