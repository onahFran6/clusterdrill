# q104-41: Abort a canary and return traffic to stable

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-41-canary-abort-rollback-to-stable`

Two Deployments already sit behind a shared Service `search-svc` (selector `app=search`, no
`track` in the selector) in namespace `q104-41-canary-abort-rollback-to-stable`:

- `search-stable` (7 replicas, image `nginx:1.24-alpine`, labels `app=search, track=stable`)
- `search-canary` (3 replicas, image `nginx:1.25-alpine`, labels `app=search, track=canary`)

Abort the canary: scale `search-canary` to `0` replicas and `search-stable` to `10` replicas so
`search-svc` endpoints are stable-only. Do not delete `search-canary`, and do not change either
Deployment's image or the Service.

## Hint

Search kubernetes.io/docs for **"kubectl scale deployment replicas"** - the `kubectl scale`
command reference shows how to change a Deployment's replica count. In this shared-selector
canary pattern, scaling the canary to zero and restoring stable's count retracts all canary
traffic while leaving the canary Deployment in place for a later retry.
