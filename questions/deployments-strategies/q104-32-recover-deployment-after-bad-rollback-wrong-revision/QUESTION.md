# q104-32: Recover from a rollback to the wrong revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-32-recover-deployment-after-bad-rollback-wrong-revision`

A Deployment named `billing-sync` (2 replicas) already exists in namespace
`q104-32-recover-deployment-after-bad-rollback-wrong-revision` with three recorded revisions:

1. image `busybox:1.34`, change-cause "initial release v1"
2. image `busybox:1.35`, change-cause "release v2 - current known-good target"
3. image `busybox:1.36`, change-cause "release v3 - broken, do not use"

A mistaken rollback put `billing-sync` back on `busybox:1.34` - the oldest image, not the
known-good one. Inspect the rollout history, find which revision runs `busybox:1.35`, and get
the Deployment onto that image so it reaches 2 ready replicas on `busybox:1.35` again.

## Hint

Search kubernetes.io/docs for **"rollout undo"** - the Deployment concept page's "Rolling Back a
Deployment" section shows `kubectl rollout history --revision=N` for inspecting what a specific
revision contains, and `kubectl rollout undo --to-revision=N` for targeting that revision
instead of blindly undoing to the previous one.
