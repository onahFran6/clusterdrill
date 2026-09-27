# q106-30-resourcequota-blocks-new-pod-with-limits: Diagnose a ResourceQuota rejection blocking new Pod creation and right-size the request

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-30-resourcequota-blocks-new-pod-with-limits`

Namespace `q106-30-resourcequota-blocks-new-pod-with-limits` already has a ResourceQuota named
`team-quota` that caps the namespace at `requests.cpu: 500m` and `requests.memory: 256Mi`, and a
running Pod named `existing-worker` that already uses `requests.cpu: 400m` and
`requests.memory: 200Mi`. That leaves `100m` CPU and `56Mi` memory of headroom.

Create a Deployment named `new-worker` with:

- 1 replica
- container image `nginx:1.25-alpine`
- a container resource request that fits in the remaining headroom

Leave ResourceQuota `team-quota` unchanged. When you are done:

- Deployment `new-worker` has `1/1` ready replicas.
- Its container `resources.requests.cpu` is at most `100m` and `resources.requests.memory` is at
  most `56Mi`.
- Total `requests.cpu` and `requests.memory` across all Pods in the namespace stay within
  `team-quota`'s hard limits.

## Hint

Search kubernetes.io/docs for **"resource quotas requests vs limits"** and separately for
**"viewing and setting quotas"**. A Pod with no requests, or one that copies `existing-worker`'s
`400m`/`200Mi` request, is rejected with an `exceeded quota` error. `kubectl describe
resourcequota` shows how much of the quota is already used.
