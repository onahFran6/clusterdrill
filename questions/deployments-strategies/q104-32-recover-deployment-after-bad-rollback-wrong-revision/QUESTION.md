# q104-32-recover-deployment-after-bad-rollback-wrong-revision: Recover from a rollback that targeted the wrong revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-32-recover-deployment-after-bad-rollback-wrong-revision`

`setup.sh` already created a Deployment named `billing-sync` (2 replicas) in namespace
`q104-32-recover-deployment-after-bad-rollback-wrong-revision` with three recorded revisions:

1. image `busybox:1.34`, change-cause "initial release v1"
2. image `busybox:1.35`, change-cause "release v2 - current known-good target"
3. image `busybox:1.36`, change-cause "release v3 - broken, do not use"

Someone then ran `kubectl rollout undo deployment/billing-sync --to-revision=1` by mistake (meant
to target a different revision number), so `billing-sync` is now back on `busybox:1.34` - the
*oldest* image, not the current known-good one.

Inspect `kubectl rollout history deployment/billing-sync -n
q104-32-recover-deployment-after-bad-rollback-wrong-revision` (and `--revision=N` for details) to
find which revision actually runs `busybox:1.35`, then get the Deployment back onto that image so
it reaches 2 ready replicas on `busybox:1.35` again.

## Hint

Search kubernetes.io/docs for **"rollout undo"** - the Deployment concept page's "Rolling Back a
Deployment" section shows `kubectl rollout history --revision=N` for inspecting what a specific
revision actually contains before undoing to it.
