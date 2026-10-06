# q116-13: Lock the namespace, keep it working inside

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-13-lock-the-namespace-keep-it-working-inside`
(plus a second namespace, `q116-13-lock-the-namespace-keep-it-working-inside-outside`)

This namespace runs Service `b-svc` (port `80`, with its matching Deployment) and a pod,
`client`. The other namespace,
`q116-13-lock-the-namespace-keep-it-working-inside-outside`, runs a Service `outside-svc`. This
namespace must be sealed - no traffic in or out by default - but pods inside it must still talk
to each other by Service name.

- Create three NetworkPolicies: `deny-all` (all ingress and egress, for every pod), `allow-dns`
  (every pod may query cluster DNS), and `allow-same-ns` (every pod may talk to every other pod in
  this namespace, in both directions).
- (ungraded, Task narrative only) From pod `client`, record the results of requesting `b-svc`,
  the public internet, and the other namespace's `outside-svc`.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy"** - a policy with both `policyTypes` set and no
rules denies everything of those types. Inside a `from` or `to` list, a bare `podSelector: {}`
means "every pod in this policy's own namespace." Same-namespace traffic needs an egress
allowance on the sender *and* an ingress allowance on the receiver.
