# q107-13: Debug the node itself with a privileged debug pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-13-debug-node-shell`

You need to inspect this cluster's node filesystem, not a container. Namespace
`q107-13-debug-node-shell` is empty.

Start a node debugging session against this cluster's only node:

- run `kubectl debug node/<node-name>` (find the node name with `kubectl get nodes`)
- use image `busybox:1.36`
- create the debug pod in namespace `q107-13-debug-node-shell`
- leave the resulting pod name as Kubernetes creates it (it starts with `node-debugger-`)

The host root filesystem must be mounted at `/host` on that debug pod.

## Hint

Search kubernetes.io/docs for **"kubectl debug node"** - the debugging nodes task page shows how
`kubectl debug node/<node-name> -it --image=<image>` creates a pod on that node with the host
filesystem mounted at `/host`. Pass `-n q107-13-debug-node-shell` so the pod lands in this
namespace. A command such as `chroot /host sh -c "echo host-debug-ok"` shows you can read the
host, including files under `/var/log`.
