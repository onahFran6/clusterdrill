# q104-07: Queue an image change without starting the rollout

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-07-pause-rollout-mid-update`

A Deployment named `notifications` (image `nginx:1.24-alpine`, 4 replicas) already exists
in namespace `q104-07-pause-rollout-mid-update`, fully rolled out and healthy.

Pause the `notifications` Deployment's rollouts, then update its container image to
`nginx:1.25-alpine`. Leave the Deployment paused when you're done: the live pods must keep
running the old image, and no new ReplicaSet should scale up for the new image yet.

## Hint

Search kubernetes.io/docs for **"kubectl rollout pause"** - the `kubectl rollout` command
reference explains how pausing a Deployment lets you make multiple template changes without
triggering a rollout for each one.
