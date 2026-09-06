# q101-25-rightsize-deployment-via-set-resources: Use kubectl set resources to fix a Deployment stuck under its namespace's LimitRange floor

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-25-rightsize-deployment-via-set-resources`

`setup.sh` already created a `LimitRange` named `min-container-requests` in this namespace that
enforces a **minimum** container request of `cpu=100m` and `memory=64Mi`, and a Deployment named
`lean-api` (2 replicas, image `nginx:1.25-alpine`) whose container only requests
`cpu=50m`/`memory=32Mi` - below that floor.

Every pod template the Deployment's ReplicaSet tries to create is rejected at admission because it
violates the LimitRange minimum, so `lean-api` exists but has zero available/ready replicas, and
its ReplicaSet shows `FailedCreate` events.

Diagnose the rejection with `kubectl describe replicaset` (check its Events) and/or
`kubectl get events`, then fix it imperatively with `kubectl set resources deployment/lean-api` so
the container's resources satisfy the namespace's LimitRange:

- `requests.cpu` >= `100m` and `requests.memory` >= `64Mi`
- `limits.cpu` >= `200m` and `limits.memory` >= `128Mi` (limits are also required once you set
  requests via `kubectl set resources` on a container that had none)

Do not edit the LimitRange or delete/recreate the Deployment - only change its container resources
so both replicas of `lean-api` become available and ready.

## Hint

Search kubernetes.io/docs for **"kubectl set resources"** - the kubectl reference page documents
the `set resources` subcommand for updating a workload's resource requests/limits without
re-authoring the whole manifest, and the LimitRange concept page explains how a namespace minimum
rejects pods whose requests fall below it.
