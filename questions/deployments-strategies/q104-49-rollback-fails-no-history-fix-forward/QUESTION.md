# q104-49-rollback-fails-no-history-fix-forward: Recover a Deployment that has nothing to roll back to

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-49-rollback-fails-no-history-fix-forward`

`setup.sh` already created a Deployment named `pricing-sync` in namespace
`q104-49-rollback-fails-no-history-fix-forward` with 2 replicas - and it was broken from the very
first apply: its image tag is `alpine:3.199`, which doesn't exist, so both pods are stuck in
`ImagePullBackOff` and the Deployment has never once been Ready.

Someone's instinct is to run `kubectl rollout undo`, but that won't help here: this Deployment has
only ever had **one** revision (the broken one you're looking at right now) - there is no earlier,
working revision to roll back to. Confirm this for yourself with `kubectl rollout history
deployment/pricing-sync -n q104-49-rollback-fails-no-history-fix-forward`, then fix the problem
the only way that actually works here: fix forward. Correct the image directly to the valid tag
`alpine:3.19` using `kubectl set image`, and confirm both replicas reach Ready.

## Hint

Search kubernetes.io/docs for **"rollout undo"** - the Deployment concept page's "Rolling Back a
Deployment" section explains that `rollout undo` can only target a revision that already exists in
a Deployment's history; a Deployment that has never been successfully updated has nothing earlier
to undo to, so the only path forward is correcting the current template directly.
