# q106-30-resourcequota-blocks-new-pod-with-limits: Diagnose a ResourceQuota rejection blocking new Pod creation and right-size the request

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-30-resourcequota-blocks-new-pod-with-limits`

`setup.sh` already created, in namespace `q106-30-resourcequota-blocks-new-pod-with-limits`, a
`ResourceQuota` named `team-quota` that caps the namespace's total consumption at
`requests.cpu: 500m` and `requests.memory: 256Mi`, and a running Pod named `existing-worker`
that already consumes `requests.cpu: 400m` and `requests.memory: 200Mi` of that quota -
leaving only `100m` CPU and `56Mi` memory of headroom.

Create a `Deployment` named `new-worker` with:

- 1 replica
- container image `nginx:1.25-alpine`
- a container resource request that fits inside the remaining quota headroom

A naive attempt (no resources set, or copying `existing-worker`'s `400m`/`200Mi` request) will be
rejected by the quota with an `exceeded quota` error. Investigate the rejection, work out exactly
how much headroom is left under `team-quota`, and set the container's
`resources.requests.cpu` and `resources.requests.memory` precisely so that:

- `ResourceQuota` `team-quota` itself is left unchanged.
- `Deployment` `new-worker` exists with `1/1` ready replicas.
- Its Pod template's container `resources.requests.cpu` is at most `100m` and
  `resources.requests.memory` is at most `56Mi`.
- The total `requests.cpu` and `requests.memory` across all Pods in the namespace stay within
  `team-quota`'s hard limits.

## Hint

Search kubernetes.io/docs for **"resource quotas requests vs limits"** and separately for
**"viewing and setting quotas"** - the Resource Quotas concept page explains why a Pod is
rejected once a namespace has a compute `ResourceQuota`, and shows `kubectl describe
resourcequota` for reading how much of the quota is already used.
