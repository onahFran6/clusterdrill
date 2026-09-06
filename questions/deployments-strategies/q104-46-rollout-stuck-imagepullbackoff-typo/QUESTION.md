# q104-46-rollout-stuck-imagepullbackoff-typo: Fix a rollout stuck on a typoed image tag

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-46-rollout-stuck-imagepullbackoff-typo`

`setup.sh` already created a Deployment named `auth-service` in namespace
`q104-46-rollout-stuck-imagepullbackoff-typo` with 2 replicas, originally healthy on image
`redis:7.2-alpine`. A rollout was then started to what was meant to be `redis:7.2-alpine`'s next
patch, but the image tag was typed as `redis:7.2-alpin` (missing the final `e`) - a tag that
doesn't exist. The new ReplicaSet's pod is now stuck in `ImagePullBackOff`, and because the
default `maxUnavailable` keeps at least one old pod running, the rollout has stalled with only 1
of 2 replicas updated.

Inspect the Deployment and its pods to find the bad tag, then fix `auth-service`'s image to the
correct `redis:7.2-alpine` and confirm the rollout completes with both replicas Ready.

## Hint

Search kubernetes.io/docs for **"ImagePullBackOff"** - and combine it with `kubectl describe pod`
or `kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}'` to spot a typoed image
tag before correcting it with `kubectl set image`.
