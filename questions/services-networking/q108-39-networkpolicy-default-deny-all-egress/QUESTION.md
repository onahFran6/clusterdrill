# q108-39: Author a default-deny-all-egress NetworkPolicy

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-39-networkpolicy-default-deny-all-egress`

A Deployment named `worker` (pod-template label `app=worker`) already exists in namespace
`q108-39-networkpolicy-default-deny-all-egress`.

Create a NetworkPolicy named `worker-deny-egress` that blocks **all** outbound traffic from
`worker`'s pods, with no exceptions. It must:

- select pods with `podSelector.matchLabels.app: worker`
- set `policyTypes: [Egress]`
- define no `egress` rules at all

## Hint

Search kubernetes.io/docs for **"default deny all egress traffic"** - the NetworkPolicy concept
page's recipes section shows that a NetworkPolicy with `policyTypes: [Egress]` and no `egress`
field blocks all outbound traffic from the pods it selects, the same way an empty `ingress` list
denies everything under `Ingress`.
