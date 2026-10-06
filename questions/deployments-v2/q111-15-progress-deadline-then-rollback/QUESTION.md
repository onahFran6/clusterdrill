# q111-15: Fail fast, then roll back

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-15-progress-deadline-then-rollback`

Team Saturn's `ring` Deployment (seeded, 4 replicas on `nginx:1.25`, then immediately broken with
a nonexistent tag) is stuck mid-rollout right now - the pipeline normally only learns a rollout
is broken after 10 minutes, far too slow.

- Make Kubernetes mark a `ring` rollout as failed after **60 seconds** without progress.
- Once it's marked, read the Deployment's `Progressing` condition reason (it will read
  `ProgressDeadlineExceeded`).
- Return `ring` to its last working version, and confirm the image the pods end up running.

## Hint

Search kubernetes.io/docs for **"Deployment status"** - the "Failed Deployment" section names
the spec field for the deadline. `kubectl explain deployment.spec` also shows it. Does
Kubernetes roll back by itself once the deadline passes, or does something still have to act on
it?
