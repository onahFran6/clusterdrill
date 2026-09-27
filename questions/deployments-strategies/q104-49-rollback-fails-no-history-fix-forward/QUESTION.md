# q104-49: Fix forward when rollback has no prior revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-49-rollback-fails-no-history-fix-forward`

A Deployment named `pricing-sync` already exists in namespace
`q104-49-rollback-fails-no-history-fix-forward` with 2 replicas. Both pods are stuck in
`ImagePullBackOff` and the Deployment has never been Ready.

`kubectl rollout undo` will not help here - confirm with `kubectl rollout history
deployment/pricing-sync -n q104-49-rollback-fails-no-history-fix-forward`. Fix forward: set the
image to `alpine:3.19` with `kubectl set image`, and confirm both replicas reach Ready.

## Hint

Search kubernetes.io/docs for **"rollout undo"** - the Deployment concept page's "Rolling Back a
Deployment" section explains that `rollout undo` can only target a revision that already exists in
history. A Deployment that has only ever had one (broken) revision has nothing earlier to undo to;
correct the current pod template directly instead.
