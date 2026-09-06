# q107-13: Debug the node itself with a privileged debug pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-13-debug-node-shell`

You need to inspect the underlying node's filesystem directly (for example, to check a file under
`/var/log` on the host) rather than anything inside a specific pod's container. `setup.sh` only
created the namespace `q107-13-debug-node-shell` for this task - there is no pod to fix, the task
is entirely about the node-debugging workflow itself.

Start a node debugging session against this cluster's only node:

- run `kubectl debug node/<node-name>` (find the node name with `kubectl get nodes`)
- use image `busybox:1.36`
- create the debug pod in namespace `q107-13-debug-node-shell` (pass `-n
  q107-13-debug-node-shell`)
- run a command that proves you can see the host filesystem, e.g. `chroot /host sh -c "echo
  host-debug-ok"` (the debug pod mounts the host's root filesystem at `/host`)

The resulting debug pod's name always starts with `node-debugger-` - don't rename it.

## Hint

Search kubernetes.io/docs for **"kubectl debug node"** - the debugging nodes task page shows how
`kubectl debug node/<node-name> -it --image=<image>` creates a pod on that node with the host
filesystem mounted at `/host`.
