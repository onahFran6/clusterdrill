# q104-07: Pause a Deployment before rolling out a change

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-07-pause-rollout-mid-update`

`setup.sh` already created a Deployment named `notifications` (image `nginx:1.24-alpine`, 4
replicas) in namespace `q104-07-pause-rollout-mid-update`, fully rolled out and healthy.

Pause the `notifications` Deployment's rollouts, then update its container image to
`nginx:1.25-alpine`. Because the Deployment is paused, no new ReplicaSet should actually start
rolling out yet - the live pods must keep running the old image until someone resumes it. Leave
the Deployment paused when you're done.

## Hint

Search kubernetes.io/docs for **"kubectl rollout pause"** - the `kubectl rollout` command
reference explains how pausing a Deployment lets you make multiple template changes without
triggering a rollout for each one.
