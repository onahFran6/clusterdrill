# q103-12: Run a CronJob's workload right now, without waiting for its schedule

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-12-cronjob-manual-trigger`

A CronJob named `backup-job` already exists in namespace `q103-12-cronjob-manual-trigger`,
scheduled to run once a day at midnight (`0 0 * * *`). Today's backup is needed immediately,
without waiting until midnight or changing the schedule.

Using the CronJob's existing `jobTemplate`, create a one-off Job named `backup-job-manual` in the
same namespace that runs the same pod template as `backup-job`. Do not edit `backup-job`'s
schedule.

## Hint

Search kubernetes.io/docs for **"kubectl create job from cronjob"** - the `kubectl create job`
command reference shows the `--from=cronjob/<name>` flag for triggering a CronJob's Job template
on demand.
