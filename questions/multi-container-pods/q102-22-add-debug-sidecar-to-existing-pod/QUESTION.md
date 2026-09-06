# q102-22-add-debug-sidecar-to-existing-pod: Add a debug sidecar container to an existing running Pod's spec

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-22-add-debug-sidecar-to-existing-pod`

A Deployment named `billing-api` already exists in this namespace, running
1 replica of a single container named `billing-api` (image `nginx:1.25`),
and its Pod is currently `Running`.

Edit the `billing-api` Deployment's pod template to add a second container
named `net-debug` (image `busybox:1.36`) with command
`["sh", "-c", "sleep 3600"]`, without removing or renaming the existing
`billing-api` container. Then wait for the rollout to complete.

The `billing-api` Deployment must end up with exactly two containers in its
pod template - `billing-api` and `net-debug` - and the resulting Pod must be
`Running` with 2/2 containers ready.

## Hint

Search kubernetes.io/docs for **"kubectl edit"** - the kubectl Cheat Sheet's
"Updating Resources" section shows how to edit a live Deployment's pod
template in place to add a container, which then triggers a new rollout.
