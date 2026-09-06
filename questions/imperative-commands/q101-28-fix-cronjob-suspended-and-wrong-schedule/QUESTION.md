# q101-28-fix-cronjob-suspended-and-wrong-schedule: Diagnose why a CronJob never fires and fix schedule plus suspend flag imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-28-fix-cronjob-suspended-and-wrong-schedule`

`setup.sh` already created a CronJob named `log-rotator` in namespace
`q101-28-fix-cronjob-suspended-and-wrong-schedule`, running image `busybox:1.36` with the command
`sh -c "echo rotate"`. It has never produced a single Job, and the on-call engineer who owns it
insists "the schedule looks fine to me".

Diagnose why `log-rotator` never fires by inspecting `kubectl get cronjob log-rotator -o yaml`
(or `kubectl describe cronjob log-rotator`) - there are two independent problems, not one. Fix
both imperatively, using `kubectl patch` and/or `kubectl edit` (do not delete and recreate the
CronJob with `kubectl create cronjob` unless you also re-apply both fixes to the replacement):

- `log-rotator` must be unsuspended (`spec.suspend` must be `false`).
- `log-rotator`'s `spec.schedule` must be a valid, frequently-firing five-field cron expression
  (for example `*/2 * * * *`) instead of the date that can never occur that it currently has.

Do not change the container image or command. Leave `log-rotator` running long enough for the
fixed schedule to actually launch a Job that completes - the grader polls for up to 3 minutes.

## Hint

Search kubernetes.io/docs for **"cronjob schedule syntax"** - the CronJob concept page covers
both the five-field cron schedule format and the `spec.suspend` field under "Suspend".
