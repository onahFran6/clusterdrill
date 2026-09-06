# q102-09: Shared process namespace for debugging

**Domain:** Application Design and Build · **Points:** 7 · **Namespace:** `q102-09-shared-process-namespace-debug`

Create a Pod named `debuggable-app` in this namespace with process namespace
sharing enabled between its containers, so a debugging sidecar can see and
signal the processes of the main application container:

- Set `spec.shareProcessNamespace: true`.
- Main container named `main` (image `nginx:1.27-alpine`).
- A second container named `debugger` (image `busybox:1.36`) that just stays
  running, e.g. `sleep 3600`, so someone can `kubectl exec` into it and run
  `ps aux` to observe the `nginx` processes from the `main` container.

## Hint

Search kubernetes.io/docs for **"share process namespace between containers
in a pod"** - the Pods concept page's Debugging section covers
`shareProcessNamespace` and its use for troubleshooting.
