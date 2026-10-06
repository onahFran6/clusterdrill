# q113-16: Lock down egress without breaking DNS

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-16-egress-without-breaking-dns`

Team Mira's `backend` pod (`app=backend`) must only be able to talk to the database pod
(`app=db`, behind `db-svc:5432`). It must still be able to look up Service names.

- Create NetworkPolicy `backend-egress` that limits `backend`'s outgoing traffic to TCP 5432 on
  `db` pods, plus DNS (UDP and TCP 53 to `kube-system`'s `kube-dns` pods).

This cluster's default CNI does not enforce NetworkPolicy, so grading checks the policy
object's fields only, not live traffic blocking.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy" "egress"** - the Network Policies concept page's
egress example locks a pod down to specific destinations. Write the database rule alone first and
predict what breaks: where does DNS run, which label does it carry, and on which ports and
protocols? Every pod's own namespace gets an automatic `kubernetes.io/metadata.name` label, so you
can select `kube-system` without labelling it yourself.
