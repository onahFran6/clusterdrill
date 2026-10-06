# q111-07: Canary behind one Service

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-07-canary-shared-service-selector`

Team Neptune's shop runs as Deployment `shop-v1` (seeded, 10 replicas, pod labels `app=shop,
version=v1`) behind Service `shop` (seeded, selector `app=shop, version=v1`, port 80). They want
to test `nginx:1.27` on a small share of real traffic first.

- Create Deployment `shop-v2` running `nginx:1.27` with env var `RELEASE=canary`, so that Service
  `shop` sends about **20%** of traffic to it.
- The shop must run exactly **10** pods in total. Do not create another Service.
- Confirm Service `shop`'s endpoints total 10 once both Deployments are in place.

## Hint

Search kubernetes.io/docs for **"deployment canary pattern"** - the Deployment concept page's
canary note explains how a second Deployment, matching the same Service selector, shares traffic
proportionally to its replica count. Read the Service's current selector first: would it ever
match v2 pods as it stands? Change it last, once `shop-v2` is Ready.
