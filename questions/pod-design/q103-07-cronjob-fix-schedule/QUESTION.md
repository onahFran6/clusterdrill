# q103-07: Fix a CronJob's broken schedule

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-07-cronjob-fix-schedule`

`setup.sh` already created a CronJob named `nightly-report` in namespace
`q103-07-cronjob-fix-schedule`. It was meant to run **every day at 02:00**, but whoever wrote the
manifest got the cron expression wrong and it currently fires every minute instead.

Fix `nightly-report`'s `.spec.schedule` so it runs at `02:00` every day. Do not change the
container image, command, or any other field.

## Hint

Search kubernetes.io/docs for **"cronjob schedule syntax"** - the CronJob concept page shows the
five-field cron schedule format and links to the crontab syntax it follows.
