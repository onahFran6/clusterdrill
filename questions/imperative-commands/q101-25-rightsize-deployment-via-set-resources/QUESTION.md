# q101-25: Right-size a Deployment blocked by LimitRange

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-25-rightsize-deployment-via-set-resources`

Namespace `q101-25-rightsize-deployment-via-set-resources` has a LimitRange named
`min-container-requests` and a Deployment named `lean-api` (2 replicas, image
`nginx:1.25-alpine`). The Deployment exists but has zero available/ready replicas; its ReplicaSet
shows `FailedCreate` events.

Investigate with `kubectl describe replicaset` and/or `kubectl get events`, then fix the
Deployment imperatively so its container resources satisfy the namespace LimitRange:

- `requests.cpu` >= `100m` and `requests.memory` >= `64Mi`
- `limits.cpu` >= `200m` and `limits.memory` >= `128Mi`

Do not edit the LimitRange or delete/recreate the Deployment - only change the container
resources so both replicas of `lean-api` become available and ready.

## Hint

Search kubernetes.io/docs for **"kubectl set resources"** - the kubectl reference page documents
the `set resources` subcommand for updating a workload's resource requests/limits without
re-authoring the whole manifest, and the LimitRange concept page explains how a namespace minimum
rejects pods whose requests fall below it.
