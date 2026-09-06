# q101-02: Create a pod with labels and a container port

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-02-create-pod-labels-port`

The platform team wants a quick smoke-test pod that's already labeled correctly so it can be
picked up by a Service later.

In namespace `q101-02-create-pod-labels-port`, create a pod named `label-demo` running image
`httpd:2.4-alpine`, that:

- carries the labels `app=label-demo` and `tier=frontend`
- exposes container port `8080`

Do this with a single imperative `kubectl run` invocation (flags only, no hand-written YAML).

## Hint

Search kubernetes.io/docs for **"kubectl run --labels --port"** - the `kubectl run` command
reference lists the flags for setting labels and a container port at creation time.
