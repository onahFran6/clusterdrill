# q113-13: An Ingress with three faults

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-13-ingress-three-faults`

Team Aldebaran's Ingress `portal` should route requests to Service `portal-svc`, which is
healthy (port 80, backed by a running Deployment). Something about `portal` itself is wrong.

- Fix Ingress `portal` only, so its rule correctly reaches `portal-svc` on port 80 under IngressClass
  `nginx`.
- (ungraded, Task narrative only) Identify each of the three faults, in the order you'd meet
  them, and the HTTP status each would produce through a real controller: a missing
  `ingressClassName` (with no default class configured) means no controller ever picks the
  object up at all, which answers as a 404; a rule that matches but names a backend Service that
  doesn't exist, or a real Service on the wrong port, both answer as a 503. This cluster has no
  Ingress controller installed, so these statuses are narrative only here - grading checks the
  object's final fields.

## Hint

Search kubernetes.io/docs for **"IngressClass"** and **"Ingress" "default backend"** - the
Ingress concept page covers both what happens when no class is set and no default exists (no
controller ever serves the object), and that a backend always names a **Service**, never a
container port directly. `kubectl describe ingress` surfaces backend resolution errors even
without a live controller.
