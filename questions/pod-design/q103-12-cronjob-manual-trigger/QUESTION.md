# q103-12: Run a CronJob's workload right now, without waiting for its schedule

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-12-cronjob-manual-trigger`

`setup.sh` already created a CronJob named `backup-job` in namespace
`q103-12-cronjob-manual-trigger`, scheduled to run once a day at midnight (`0 0 * * *`). A teammate
needs today's backup immediately and doesn't want to wait until midnight or change the schedule.

Using the CronJob's existing `jobTemplate`, create a one-off Job named `backup-job-manual` in the
same namespace that runs the exact same pod template as `backup-job`, without editing
`backup-job`'s schedule.

## Hint

Search kubernetes.io/docs for **"kubectl create job from cronjob"** - the `kubectl create job`
command reference shows the `--from=cronjob/<name>` flag for triggering a CronJob's Job template
on demand.
