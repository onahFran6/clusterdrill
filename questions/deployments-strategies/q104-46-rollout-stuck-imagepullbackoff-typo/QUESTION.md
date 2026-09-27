# q104-46: Unstick a rollout stuck on ImagePullBackOff

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-46-rollout-stuck-imagepullbackoff-typo`

A Deployment named `auth-service` already exists in namespace
`q104-46-rollout-stuck-imagepullbackoff-typo` with 2 replicas. A rollout is stuck: a new pod is
in `ImagePullBackOff`, and only 1 of 2 replicas has updated.

Inspect the Deployment and its pods, correct `auth-service`'s image to `redis:7.2-alpine`, and
confirm the rollout completes with both replicas Ready.

## Hint

Search kubernetes.io/docs for **"ImagePullBackOff"** - combine it with `kubectl describe pod` or
`kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}'` to spot a bad image tag
before correcting it with `kubectl set image`. A typoed tag that doesn't exist leaves the new
ReplicaSet unable to pull, which stalls the rolling update.
