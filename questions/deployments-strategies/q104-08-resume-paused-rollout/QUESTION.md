# q104-08: Resume a paused Deployment and let the rollout finish

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-08-resume-paused-rollout`

`setup.sh` already created a Deployment named `reporting` (3 replicas) in namespace
`q104-08-resume-paused-rollout`. The Deployment is currently **paused**, and its pod template's
image has already been changed to `nginx:1.25-alpine` while paused, but the live pods are still
serving the old `nginx:1.24-alpine` image because nothing has resumed the rollout yet.

Resume `reporting` so the pending image change actually rolls out, and confirm all 3 replicas
become ready on the new image.

## Hint

Search kubernetes.io/docs for **"kubectl rollout resume"** - the `kubectl rollout` command
reference documents `resume` as the counterpart to `pause`, letting queued template changes
finally roll out.
