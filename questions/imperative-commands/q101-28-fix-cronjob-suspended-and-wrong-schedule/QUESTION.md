# q101-28: Fix a CronJob that never fires

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-28-fix-cronjob-suspended-and-wrong-schedule`

A CronJob named `log-rotator` exists in namespace
`q101-28-fix-cronjob-suspended-and-wrong-schedule` (image `busybox:1.36`, command
`sh -c "echo rotate"`). It has never produced a Job.

Investigate with `kubectl get cronjob log-rotator -o yaml` or `kubectl describe cronjob
log-rotator`, then fix it imperatively (`kubectl patch` and/or `kubectl edit` - do not delete and
recreate unless you re-apply the same fixes to the replacement) so that:

- `log-rotator` is not suspended (`spec.suspend` is `false`).
- `log-rotator`'s `spec.schedule` is a valid, frequently-firing five-field cron expression (for
  example `*/2 * * * *`).
- The container image and command are unchanged.

Leave it running long enough for the fixed schedule to launch a Job that completes - the grader
polls for up to 3 minutes.

## Hint

Search kubernetes.io/docs for **"cronjob schedule syntax"** - the CronJob concept page covers
both the five-field cron schedule format and the `spec.suspend` field under "Suspend".
