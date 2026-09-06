# q104-31-fix-canary-selector-leak-wrong-traffic-split: Remove a stray Deployment leaking traffic into a canary Service

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-31-fix-canary-selector-leak-wrong-traffic-split`

`setup.sh` already created, in namespace `q104-31-fix-canary-selector-leak-wrong-traffic-split`:

- A Service named `recs-svc` selecting pods labeled `app=recs` (no `tier` in its selector, so it
  intentionally matches both the stable and canary Deployments below).
- Deployment `recs-stable` - 3 replicas, labels `app=recs, tier=stable`.
- Deployment `recs-canary` - 1 replica, labels `app=recs, tier=canary`.
- Deployment `recs-debug-leftover` - 2 replicas, labels `app=recs` **only** (no `tier`) - a stray
  debugging Deployment someone forgot to clean up. Because it also carries `app=recs`, `recs-svc`
  is unintentionally sending it a share of production traffic too, on top of the intended 3:1
  stable:canary split.

Fix the leak: remove **only** `recs-debug-leftover` (the stray Deployment) so `recs-svc` ends up
selecting **exactly 4** Running pods total - the 3 `recs-stable` pods and the 1 `recs-canary` pod,
and nothing else. Do not change `recs-stable` or `recs-canary` in any way.

## Hint

Search kubernetes.io/docs for **"Service without selector"** and **"Canary Deployments"** - a
Service's `selector` matches on labels alone, so any Deployment whose pods happen to carry a
matching label receives traffic too, whether or not that was intended.
