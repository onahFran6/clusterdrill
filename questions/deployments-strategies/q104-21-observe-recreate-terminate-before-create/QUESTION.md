# q104-21: Roll a Recreate Deployment to a new image

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-21-observe-recreate-terminate-before-create`

A Deployment named `batch-loader` already exists in namespace
`q104-21-observe-recreate-terminate-before-create` with 3 replicas of image `busybox:1.36`
and `spec.strategy.type: Recreate`.

Update `batch-loader`'s container image to `busybox:1.36.1` and wait for the rollout to
finish. When you are done, the Deployment must have 3 ready replicas, and every running pod
labeled `app=batch-loader` must be on image `busybox:1.36.1` (none still on `busybox:1.36`).

## Hint

Search kubernetes.io/docs for **"kubectl set image"** and **"rollout status"** - the Deployment
concept page's "Recreate Deployment" section explains why this strategy tears down every old pod
before starting any new one, unlike `RollingUpdate`.
