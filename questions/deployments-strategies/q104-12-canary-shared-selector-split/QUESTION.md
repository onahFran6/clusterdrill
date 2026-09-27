# q104-12: Stand up a canary Deployment behind a shared Service

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-12-canary-shared-selector-split`

A Deployment named `orders-stable` (9 replicas, image `nginx:1.24-alpine`) already exists in
namespace `q104-12-canary-shared-selector-split`, along with a Service named `orders-svc` that
selects on `app=orders` (no `track` in the selector) on port `80`. `orders-stable`'s pods carry
labels `app=orders, track=stable`.

Create a second Deployment named `orders-canary` with `1` replica of image `nginx:1.25-alpine`
and pod labels `app=orders, track=canary`, so it matches `orders-svc` and shares traffic with the
stable pods. Do not change `orders-stable` or `orders-svc`.

## Hint

Search kubernetes.io/docs for **"deployment canary pattern"** - the Deployment concept page's
"Canary Deployment" note explains how a second Deployment with fewer replicas, matching the same
Service selector, routes a small fraction of traffic to a new version. With 1 canary pod and 9
stable pods behind one selector, roughly 10% of endpoints are canary.
