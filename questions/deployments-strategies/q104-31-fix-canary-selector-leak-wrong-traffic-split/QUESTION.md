# q104-31: Remove a stray Deployment leaking into a canary Service

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-31-fix-canary-selector-leak-wrong-traffic-split`

You'll find these objects in namespace `q104-31-fix-canary-selector-leak-wrong-traffic-split`:

- A Service named `recs-svc` selecting pods labeled `app=recs` (no `tier` in its selector)
- Deployment `recs-stable` - 3 replicas, labels `app=recs, tier=stable`
- Deployment `recs-canary` - 1 replica, labels `app=recs, tier=canary`
- Deployment `recs-debug-leftover` - 2 replicas, labels `app=recs` only (no `tier`)

`recs-svc` is matching more pods than the intended 3:1 stable:canary split. Remove **only**
`recs-debug-leftover` so `recs-svc` selects exactly **4** Running pods - the 3 `recs-stable`
pods and the 1 `recs-canary` pod. Do not change `recs-stable` or `recs-canary`.

## Hint

Search kubernetes.io/docs for **"Service without selector"** and **"Canary Deployments"** - a
Service's `selector` matches on labels alone, so any Deployment whose pods carry a matching
label receives traffic too, whether or not that was intended. A leftover Deployment that only
shares the Service's labels will dilute a canary split until it is removed.
