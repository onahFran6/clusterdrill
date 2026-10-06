# q116-18: Which policy let it in?

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-18-which-policy-let-it-in`

This namespace has three NetworkPolicies already applied: `deny-all-ingress`, `db-from-api`
(correct, intended), and one more that nobody remembers the purpose of. The team expects only
`api` (label `app: api`) to reach `db` (label `app: db`, Service `db-svc`), but `intruder`
(label `app: intruder`) also gets through.

- Find the policy responsible for the leak and remove it. Leave the other two policies
  completely untouched.
- (ungraded, Task narrative only) Write the responsible policy's name, and why it allowed
  `intruder`, then confirm `api` can still connect.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy"** - policies are never in conflict: traffic is
allowed if *any* policy selecting the pod allows it. `kubectl describe networkpolicy` shows each
one's effective "Allowing ingress traffic: To Port / From" line. What does a single empty rule,
`ingress: [{}]`, match - compared with `ingress: []` or no `ingress` key at all?
