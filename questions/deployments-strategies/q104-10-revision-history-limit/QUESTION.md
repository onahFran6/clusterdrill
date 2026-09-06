# q104-10: Limit how many old ReplicaSets a Deployment keeps around

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-10-revision-history-limit`

`setup.sh` already created a Deployment named `audit-log` in namespace
`q104-10-revision-history-limit` and rolled it through five separate image updates, so five old,
scaled-to-0 ReplicaSets are currently sitting around behind it in addition to the live one.

Set `audit-log`'s `revisionHistoryLimit` to `2`, then trigger one more rollout (update the image
to `nginx:1.26-alpine`) so the controller actually prunes old ReplicaSets down to the new limit.
When you're done, no more than 2 old (non-active) ReplicaSets should remain alongside the current
one.

## Hint

Search kubernetes.io/docs for **"deployment revisionHistoryLimit"** - the Deployment concept
page's "Clean up Policy" section explains how this field caps the number of old ReplicaSets kept
for rollback purposes.
