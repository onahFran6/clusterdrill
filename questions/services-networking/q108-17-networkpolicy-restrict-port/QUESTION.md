# q108-17: Narrow an already-open policy down to one port

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-17-networkpolicy-restrict-port`

`setup.sh` already created a Deployment `admin-panel` (pod-template label `app=admin-panel`,
container exposing both port `8443` for the real admin UI and port `9000` for an internal debug
endpoint that should never be reachable from other pods) in namespace
`q108-17-networkpolicy-restrict-port`. It also created a NetworkPolicy named
`admin-panel-ingress` that already selects `app=admin-panel` pods and already allows ingress from
pods matching `app=ops-console`, but the existing policy has **no `ports` field at all** - meaning
it currently allows the `ops-console` pods to reach *every* port on `admin-panel`, including the
debug port `9000`.

Edit the existing NetworkPolicy `admin-panel-ingress` so its ingress rule allows traffic **only**
on TCP port `8443`, closing off the debug port without changing the existing `podSelector` or
`from` selector.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page shows that omitting
`ports` in an ingress rule means "all ports," and that adding a `ports` list is how you scope a
rule down to specific ports and protocols.
