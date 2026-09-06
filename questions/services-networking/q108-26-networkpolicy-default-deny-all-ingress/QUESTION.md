# q108-26-networkpolicy-default-deny-all-ingress: Create a default-deny-all-ingress NetworkPolicy for a namespace

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-26-networkpolicy-default-deny-all-ingress`

`setup.sh` already created a Deployment `internal-svc` (pod-template label `app=internal-svc`,
container port `8080`) and a matching Service `internal-svc` in namespace
`q108-26-networkpolicy-default-deny-all-ingress`, along with a `probe-client` pod in the same
namespace that setup.sh used to confirm `internal-svc` can currently be reached over the network -
right now there is no NetworkPolicy in this namespace at all, so every pod can accept inbound
traffic from anywhere.

Lock the namespace down: create a NetworkPolicy named exactly `default-deny-ingress` in
`q108-26-networkpolicy-default-deny-all-ingress` that blocks **all** inbound traffic to **every**
pod in the namespace, with no exceptions. Concretely, the NetworkPolicy must:

- select every pod in the namespace (an empty `podSelector: {}`)
- set `policyTypes` to `[Ingress]` only
- define no `ingress` rules at all (an empty/absent ingress list), so nothing is ever allowed in

## Hint

Search kubernetes.io/docs for **"default deny all ingress traffic"** - the Network Policies
concept page's "Default policies" section has a copy-paste example manifest for exactly this
default-deny pattern.
