# q102-25-ambassador-wrong-port-two-services: Ambassador proxy forwards to the wrong of two backend Services

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-25-ambassador-wrong-port-two-services`

Two backend Services already exist in this namespace, each backed by its
own Deployment and each serving a distinguishable response body on port
`8080`:

- `catalog-primary` - responds with the body `PRIMARY`.
- `catalog-standby` - responds with the body `STANDBY`.

A Pod named `catalog-gateway` also already exists with two containers:

- `client` - the application container. It is only ever configured to call
  `http://localhost:9090` and must never be changed to call a Service
  directly (that is the whole point of the ambassador pattern).
- `proxy` - the ambassador container, which listens on `localhost:9090`
  inside the Pod and forwards traffic to one of the two backend Services on
  port `8080`. It is currently misconfigured: it forwards to
  `catalog-standby` instead of `catalog-primary`.

Fix the `proxy` container so that traffic sent to `localhost:9090` inside
the Pod is forwarded to `catalog-primary:8080` instead of
`catalog-standby:8080`. You cannot change a running Pod's container
command/env in place, so delete and recreate `catalog-gateway` with the
`proxy` container's forwarding target corrected, keeping the `client`
container, its command, and both container images unchanged. When you are
done, running `curl` (or `wget`) from inside the `client` container against
`localhost:9090` must return the body `PRIMARY`.

## Hint

Search kubernetes.io/docs for **"multi-container pods communicate"** - the
Pods concept page's "Communication between containers in the same Pod"
section describes the ambassador container pattern this task is based on.
