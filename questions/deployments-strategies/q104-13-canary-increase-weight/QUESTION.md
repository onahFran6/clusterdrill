# q104-13: Widen a canary's traffic share by rebalancing replica counts

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-13-canary-increase-weight`

Two Deployments already sit behind a shared Service `payments-svc` (selector `app=payments`, no
`track` in the selector) in namespace `q104-13-canary-increase-weight`:

- `payments-stable` (9 replicas, image `nginx:1.24-alpine`, labels `app=payments, track=stable`)
- `payments-canary` (1 replica, image `nginx:1.25-alpine`, labels `app=payments, track=canary`)

Rebalance them so `payments-canary` has `5` replicas and `payments-stable` has `5` replicas,
keeping the total pod count behind `payments-svc` at `10`. Do not change either Deployment's
image or the Service.

## Hint

Search kubernetes.io/docs for **"kubectl scale deployment replicas"** - the `kubectl scale`
command reference shows how to change a Deployment's replica count. In this shared-selector
canary pattern, replica counts are the lever for widening or narrowing the canary's traffic
share.
