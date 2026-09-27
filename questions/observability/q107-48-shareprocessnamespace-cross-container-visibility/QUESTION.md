# q107-48: Let a watchdog sidecar see another container's process

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-48-shareprocessnamespace-cross-container-visibility`

A Pod named `monitored-app` already exists with two containers: `main-app` (runs `sleep 424242`)
and `watchdog`. `ps` inside `watchdog` shows only `watchdog`'s own process. It cannot see
`main-app`.

Fix the Pod so `watchdog` can see `main-app`'s process via `ps`. Do not change either container's
command or image.

## Hint

Search kubernetes.io/docs for **"share process namespace between containers in a pod"** - the task
page covers `spec.shareProcessNamespace`, a Pod-level field that puts every container in the same
process namespace so tools like `ps` in one container can see processes from every container in
the Pod. By default each container has its own process namespace.
