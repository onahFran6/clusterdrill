# q101-41-create-job-from-cronjob: Trigger a CronJob's Job manually, right now

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-41-create-job-from-cronjob`

`setup.sh` already created a suspended CronJob named `nightly-report` (image `busybox:1.36`,
schedule `0 2 * * *`, running `echo generating-report`) in namespace
`q101-41-create-job-from-cronjob`. It is suspended, so it will never fire on its own schedule.

Without waiting for the schedule or un-suspending it, run this CronJob's job **right now** as a
one-off Job named `manual-report-run`, using a single imperative `kubectl create job --from=cronjob/...`
command. Let it run to completion.

## Hint

Search kubernetes.io/docs for **"kubectl create job from cronjob"** - the CronJob concept page's
"Manual Triggering" note shows the `kubectl create job <name> --from=cronjob/<cronjob-name>` form
for running a CronJob's job template immediately, outside its schedule.
