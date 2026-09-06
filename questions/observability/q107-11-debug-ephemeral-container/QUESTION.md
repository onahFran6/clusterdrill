# q107-11: Attach an ephemeral debug container to a running pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-11-debug-ephemeral-container`

`setup.sh` already created a running pod named `payments-api` (image `nginx:1.25-alpine`) in
namespace `q107-11-debug-ephemeral-container`. The container image has no shell debugging tools
worth adding permanently, but you need to poke around inside the running pod's network/process
namespace right now without restarting it or building a new image.

Attach an ephemeral container to the running `payments-api` pod:

- name the ephemeral container `debugger`
- use image `busybox:1.36`
- target the existing `payments-api` container (so it shares its process namespace)

The pod itself must keep running unmodified other than the ephemeral container being added.

## Hint

Search kubernetes.io/docs for **"kubectl debug ephemeral container"** - the debugging running pods
task page shows the `kubectl debug <pod> -it --image=... --target=... --container=<name>` form for
attaching a temporary troubleshooting container to a pod that's already running.
