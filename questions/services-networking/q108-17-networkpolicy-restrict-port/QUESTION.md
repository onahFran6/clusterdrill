# q108-17: Narrow an already-open policy down to one port

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-17-networkpolicy-restrict-port`

A Deployment `admin-panel` (pod-template label `app=admin-panel`,
container exposing both port `8443` for the admin UI and port `9000` for an internal debug
endpoint) already exists in namespace `q108-17-networkpolicy-restrict-port`, along with a
NetworkPolicy named `admin-panel-ingress`. That policy already selects `app=admin-panel` pods and
already allows ingress from pods matching `app=ops-console`, but it does not limit which ports
those clients can reach. The debug port `9000` must not stay open.

Edit `admin-panel-ingress` so its ingress rule allows traffic **only** on TCP port `8443`,
without changing the existing `podSelector` or `from` selector.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page shows that omitting
`ports` in an ingress rule means all ports, and that adding a `ports` list scopes a rule to
specific ports and protocols.
