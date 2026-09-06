# q107-48: Let a watchdog sidecar see another container's process

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-48-shareprocessnamespace-cross-container-visibility`

`setup.sh` already created a Pod named `monitored-app` with two containers: `main-app` (runs
`sleep 424242`) and `watchdog` (meant to monitor `main-app`'s process). Right now, running `ps`
inside `watchdog` shows only its own process - it can't see `main-app` at all, because each
container gets its own isolated process namespace by default. Fix the Pod so `watchdog` can see
`main-app`'s process via `ps`, without changing either container's own command or image.

## Hint

Search kubernetes.io/docs for **"share process namespace between containers in a pod"** - the task
page covers `spec.shareProcessNamespace`, a Pod-level field that puts every container in the same
process namespace so tools like `ps` in one container can see processes from every container in
the Pod.
