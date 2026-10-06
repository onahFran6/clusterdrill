# q116-17: The policy that protects nothing

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-17-the-policy-that-protects-nothing`
(plus a second namespace, `q116-17-the-policy-that-protects-nothing-wrong`)

This namespace runs pod `web` (label `app: web`, lowercase, with its matching Service) and two
test pods, `frontend` (label `app: frontend`) and `intruder` (label `app: intruder`). A
NetworkPolicy named `web-only-frontend` was supposed to make only `frontend` able to reach `web`,
but `intruder` can still reach it too - the policy has had no effect at all.

- Find out why, and fix it: the policy must end up named `web-only-frontend`, in this namespace,
  with a `podSelector` that actually matches `web`'s real (lowercase) labels, allowing ingress
  only from `app: frontend`.
- (ungraded, Task narrative only) Write down each cause you find.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy"** - a policy only affects pods that its
`podSelector` matches, **in its own namespace**. `kubectl get networkpolicy -A` shows where it
actually lives. Compare its selector against the real pod labels character by character - label
values are case-sensitive.
