# q111-13: Add a log sidecar, update only it

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-13-log-sidecar-independent-update`

Team Mercury's `orders` Deployment (seeded, single container `app`, `busybox:1.36`) writes its
log to `/var/log/app/orders.log` inside the container, so `kubectl logs` shows nothing useful.

- Add a second container `log-shipper` (`busybox:1.36`) that streams that file to its stdout
  with `tail -F`. Both containers must share the log directory through a pod-lifetime volume.
- Then upgrade **only** the sidecar to `busybox:1.37`.

## Hint

Search kubernetes.io/docs for **"multi-container pods"**. The volume has to be mounted in both
containers at the same path. For the upgrade, `kubectl set image` takes `container=image` pairs -
which pair leaves `app` untouched?
