# q107-11: Attach an ephemeral debug container to a running pod

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-11-debug-ephemeral-container`

A running pod named `payments-api` (image `nginx:1.25-alpine`) already exists in namespace
`q107-11-debug-ephemeral-container`.

Attach an ephemeral container to the running `payments-api` pod:

- name the ephemeral container `debugger`
- use image `busybox:1.36`
- target the existing `payments-api` container

The pod itself must keep running unmodified other than the ephemeral container being added.

## Hint

Search kubernetes.io/docs for **"kubectl debug ephemeral container"** - the debugging running pods
task page shows the `kubectl debug <pod> -it --image=... --target=... --container=<name>` form for
attaching a temporary troubleshooting container to a pod that's already running. Targeting the
existing container shares that container's process namespace without restarting the pod or
replacing its image. The app image has no shell worth adding permanently.
