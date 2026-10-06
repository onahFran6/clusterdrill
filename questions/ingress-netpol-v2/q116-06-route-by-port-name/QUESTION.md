# q116-06: Route by port name, health by exact path

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-06-route-by-port-name`

Services `app-svc` and `health-svc` (both port `80`) already exist, with their matching
Deployments. This team expects to renumber `app-svc`'s port later, so routing to it must not
depend on the number.

- Rename `app-svc`'s existing port to `web`, keeping the same port number.
- Create Ingress `cosmos` (class `nginx`, host `cosmos.local`): exactly `/healthz` routes to
  `health-svc` port `80`, and everything else routes to `app-svc` by its port **name** (`web`),
  not its number.
- (ungraded, Task narrative only) Predict, then record, the responses for `/healthz` and
  `/anything`.

## Hint

Search kubernetes.io/docs for **"Ingress"** - the `backend.service.port` field accepts either
`number` or `name`. Which one survives a Service being renumbered later? A Service's port name can
be patched in place without touching anything else about it.
