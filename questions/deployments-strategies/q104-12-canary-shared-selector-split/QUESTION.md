# q104-12: Stand up a canary Deployment behind a shared Service

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-12-canary-shared-selector-split`

`setup.sh` already created a Deployment named `orders-stable` (9 replicas, image
`nginx:1.24-alpine`) in namespace `q104-12-canary-shared-selector-split`, plus a Service named
`orders-svc` that selects on `app=orders` (with no `track` in its selector) on port `80`.
`orders-stable`'s pods carry labels `app=orders, track=stable`.

Create a second Deployment named `orders-canary` running `1` replica of image
`nginx:1.25-alpine`, with pod labels `app=orders, track=canary`, so it matches `orders-svc`'s
existing selector and starts receiving a small slice of traffic (1 out of 10 total pods, roughly
10%) alongside the stable version - without changing `orders-stable` or `orders-svc` at all. This
is the entire canary mechanism: two Deployments sharing one Service's label selector, split by
replica count.

## Hint

Search kubernetes.io/docs for **"deployment canary pattern"** - the Deployment concept page's
"Canary Deployment" note explains how a second Deployment with fewer replicas, matching the same
Service selector, lets you route a small fraction of traffic to a new version.
