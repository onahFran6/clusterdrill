# q113-08: A Service name that resolves nowhere

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-08-cross-namespace-dns`

Team Castor's `frontend` Deployment calls `backend` through env var `BACKEND_URL`. Every call
fails.

- Fix `frontend` so its calls reach `backend`, without moving or recreating `backend`.
- (ungraded, Task narrative only) Check `search` in `frontend`'s own `/etc/resolv.conf` - which
  namespace does a bare Service name resolve in by default?

## Hint

Search kubernetes.io/docs for **"DNS for Services and Pods" "Namespaces of Services"** - the DNS
concept page states that a bare Service name only resolves within the querying pod's own
namespace; a namespace-qualified name (`<service>.<namespace>`) is needed for anything else, and a
*wrong* namespace-qualified name fails exactly like a namespace that was never created. Changing
an env var on a running Deployment has a direct imperative command, and it starts a rollout.
