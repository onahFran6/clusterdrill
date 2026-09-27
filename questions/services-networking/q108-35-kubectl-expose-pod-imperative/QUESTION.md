# q108-35: Expose a single Pod with `kubectl expose`

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-35-kubectl-expose-pod-imperative`

A bare Pod named `cache-proxy` (image `redis:7-alpine`, container port
`6379`, label `app=cache-proxy`) already exists in namespace
`q108-35-kubectl-expose-pod-imperative`. There is no Deployment, just the Pod itself.

Using a single `kubectl expose` command (not a hand-written manifest), create a `ClusterIP`
Service named `cache-proxy-svc` that exposes this Pod on port `6379`.

## Hint

Search kubernetes.io/docs for **"kubectl expose"** - the kubectl command reference's `expose`
page shows that `expose` works directly against a Pod (not only a Deployment or ReplicaSet),
automatically copying the target's own labels into the generated Service's selector.
