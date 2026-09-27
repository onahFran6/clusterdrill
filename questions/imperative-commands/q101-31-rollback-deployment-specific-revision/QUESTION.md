# q101-31: Roll a Deployment back to a healthy historical revision

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-31-rollback-deployment-specific-revision`

A Deployment named `orders-api` exists in namespace
`q101-31-rollback-deployment-specific-revision`. Its Pods are stuck in `ImagePullBackOff` on the
image from the current (latest) revision.

Inspect the full rollout history (`kubectl rollout history deployment/orders-api` and
`--revision=N` for individual revisions), find the most recent revision that used a valid,
pullable image, and roll `orders-api` back specifically to that revision number. A plain undo to
the previous revision alone may not be enough - check each recorded revision's image before
choosing.

When you are done, `orders-api` must be running that exact historical image again with 2/2
replicas ready - not a working image patched in by hand.

## Hint

Search kubernetes.io/docs for **"kubectl rollout undo to-revision"** - the Deployment concept
page's "Rolling Back a Deployment" section covers using `kubectl rollout history --revision=N` to
inspect a specific revision's pod template before targeting it with `rollout undo
--to-revision=N`.
