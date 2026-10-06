# q113-15: Deny by default, allow one path

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-15-default-deny-allow-one-path`

Team Canopus's namespace currently accepts inbound traffic from anywhere. Pods `frontend`
(`app=frontend`) and `intruder` (`app=intruder`), and a Deployment `backend` behind
`backend-svc`, already exist.

- Create NetworkPolicy `default-deny` that blocks all inbound traffic to every pod in this
  namespace.
- Create NetworkPolicy `allow-frontend` so only `frontend` pods can reach `backend` pods on TCP
  80, and nothing else can.

This cluster's default CNI does not enforce NetworkPolicy, so grading checks each policy
object's fields only, not live traffic blocking.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy" "default deny all ingress traffic"** - the
Network Policies concept page's recipes section shows an empty `podSelector` selects every pod in
the namespace, and a policy with `policyTypes: [Ingress]` and no `ingress` rules allows nothing
in. Policies only ever add allowances, never denials, so the second policy simply adds to what the
first one already blocks.
