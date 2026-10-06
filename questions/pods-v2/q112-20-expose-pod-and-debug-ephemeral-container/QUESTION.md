# q112-20: Expose a Pod and debug it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q112-20-expose-pod-and-debug-ephemeral-container`

Pod `api` (seeded, container `web`, named port `http` on 80) needs to be reachable inside the
cluster. Its process list also needs inspecting without adding any tools to its own image.

- Create ClusterIP Service `api-svc` on port **80** that targets the container's port **by name**,
  not by number.
- Attach an ephemeral container `dbg` (`busybox:1.36`) to `api` that shares the `web` container's
  process namespace and runs `ps`.

## Hint

Search kubernetes.io/docs for **"kubectl expose"** and **"Ephemeral Containers"**. `kubectl debug`
has a flag that attaches a new container sharing one existing container's process namespace. Its
output can be read afterward with a plain `kubectl logs -c <name>`.
