# q102-25: Point an ambassador proxy at the primary backend

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-25-ambassador-wrong-port-two-services`

Two backend Services already exist in this namespace, each backed by its own
Deployment and each serving a distinguishable response body on port `8080`:

- `catalog-primary` - responds with the body `PRIMARY`.
- `catalog-standby` - responds with the body `STANDBY`.

A Pod named `catalog-gateway` also already exists with two containers:

- `client` - only ever configured to call `http://localhost:9090`. Do not
  change it to call a Service directly.
- `proxy` - the ambassador that listens on `localhost:9090` inside the Pod and
  forwards traffic to one of the two backend Services on port `8080`.

Right now, a request from `client` to `localhost:9090` does not return
`PRIMARY`. Fix `proxy` so traffic to `localhost:9090` is forwarded to
`catalog-primary:8080`. You cannot change a running Pod's container
command/env in place, so delete and recreate `catalog-gateway` with the
`proxy` forwarding target corrected, keeping the `client` container, its
command, and both container images unchanged.

When you are done, `curl` (or `wget`) from inside `client` against
`localhost:9090` must return the body `PRIMARY`.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the
Pods concept page's "Communication between containers in the same Pod"
section describes the ambassador container pattern this task is based on.
