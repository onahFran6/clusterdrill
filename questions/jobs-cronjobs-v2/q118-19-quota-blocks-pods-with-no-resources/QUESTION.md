# q118-19: Unblock digest Jobs that have no Pods

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-19-quota-blocks-pods-with-no-resources`

Team Rhea has *CronJob* `digest` and *ResourceQuota* `compute`; its Jobs cannot create any Pods.
Find the error on the object attempting to create the missing Pod (practice observation, ungraded).
Fix the CronJob so each container requests **50m CPU / 32Mi memory**, limited to **100m CPU / 64Mi memory**.
Keep the schedule, image, command, and quota unchanged.
Clear old Jobs and trigger *Job* `digest-now` to completion, then inspect quota usage (practice observation, ungraded).

## Hint

Search kubernetes.io/docs for "ResourceQuota requests vs limits"; when no Pod exists, inspect the controller that tried to create one.
