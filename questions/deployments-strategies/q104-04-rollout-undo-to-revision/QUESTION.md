# q104-04: Roll back to a specific historical revision

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-04-rollout-undo-to-revision`

`setup.sh` already created a Deployment named `billing` in namespace
`q104-04-rollout-undo-to-revision` and rolled it through three revisions:

- revision 1: image `nginx:1.23-alpine`
- revision 2: image `nginx:1.24-alpine`
- revision 3 (current): image `nginx:1.25-alpine`

Roll `billing` back specifically to **revision 1** (not just "the previous one") so its pods run
`nginx:1.23-alpine` again, and confirm the rollout completes with all replicas ready.

## Hint

Search kubernetes.io/docs for **"kubectl rollout undo to-revision"** - the `kubectl rollout`
command reference documents the `--to-revision` flag for targeting a specific revision number
instead of just the immediately preceding one.
