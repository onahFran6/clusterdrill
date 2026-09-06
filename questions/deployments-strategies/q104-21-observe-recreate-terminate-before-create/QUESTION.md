# q104-21-observe-recreate-terminate-before-create: Trigger a Recreate rollout and confirm old pods fully terminate first

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-21-observe-recreate-terminate-before-create`

`setup.sh` already created a Deployment named `batch-loader` (3 replicas, image `busybox:1.36`,
`spec.strategy.type: Recreate`) in namespace `q104-21-observe-recreate-terminate-before-create`.

Update `batch-loader`'s container image to `busybox:1.36.1`, then wait for the rollout to finish.
Because the strategy is `Recreate`, Kubernetes must terminate all 3 old pods before it creates any
new ones - there is no overlap between old and new versions during the rollout. When you are done,
the Deployment must have 3 ready replicas, and every currently running pod for `app=batch-loader`
must be on image `busybox:1.36.1` (no pod still running the old `busybox:1.36` image).

## Hint

Search kubernetes.io/docs for **"kubectl set image"** and **"rollout status"** - the Deployment
concept page's "Recreate Deployment" section explains why this strategy tears down every old pod
before starting any new one, unlike `RollingUpdate`.
