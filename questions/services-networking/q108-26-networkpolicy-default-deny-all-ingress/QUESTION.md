# q108-26: Create a default-deny-all-ingress NetworkPolicy for a namespace

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-26-networkpolicy-default-deny-all-ingress`

A Deployment `internal-svc` (pod-template label `app=internal-svc`,
container port `8080`) and a matching Service `internal-svc` already exist in namespace
`q108-26-networkpolicy-default-deny-all-ingress`. There is no NetworkPolicy in this namespace, so
every pod can accept inbound traffic from anywhere.

Create a NetworkPolicy named exactly `default-deny-ingress` in
`q108-26-networkpolicy-default-deny-all-ingress` that blocks **all** inbound traffic to **every**
pod in the namespace, with no exceptions:

- select every pod in the namespace (an empty `podSelector: {}`)
- set `policyTypes` to `[Ingress]` only
- define no `ingress` rules at all

## Hint

Search kubernetes.io/docs for **"default deny all ingress traffic"** - the Network Policies
concept page's "Default policies" section has an example of an empty `podSelector` with
`policyTypes: [Ingress]` and no `ingress` list, which denies every inbound connection.
