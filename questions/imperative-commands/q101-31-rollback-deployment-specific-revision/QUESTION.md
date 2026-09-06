# q101-31-rollback-deployment-specific-revision: Roll back a Deployment to a specific historical revision

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-31-rollback-deployment-specific-revision`

`setup.sh` already created a Deployment named `orders-api` in namespace
`q101-31-rollback-deployment-specific-revision` and rolled it through several revisions over
time. The Deployment is currently broken: its pods are stuck in `ImagePullBackOff` on the image
from the current (latest) revision.

Do not just run a plain `kubectl rollout undo` - the revision immediately before the current one
is also broken, so that only trades one broken image for another. Inspect the full rollout
history instead: `kubectl rollout history deployment/orders-api -n
q101-31-rollback-deployment-specific-revision` to list every recorded revision, then `kubectl
rollout history deployment/orders-api -n q101-31-rollback-deployment-specific-revision
--revision=N` for each one to see the exact image that revision's pod template used. Find the
most recent revision that actually ran a valid, pullable image, then roll `orders-api` back
specifically to that revision number.

When you are done, `orders-api` must be running that exact image again with 2/2 replicas ready -
not merely "some working image" patched in by hand.

## Hint

Search kubernetes.io/docs for **"kubectl rollout undo to-revision"** - the Deployment concept
page's "Rolling Back a Deployment" section covers using `kubectl rollout history --revision=N` to
inspect a specific revision's pod template before targeting it with `rollout undo
--to-revision=N`.
