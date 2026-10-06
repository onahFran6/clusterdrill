# q103-07: Fix a CronJob's broken schedule

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-07-cronjob-fix-schedule`

Catalyst Research Institute's `nightly-report` CronJob was meant to summarize the day's furnace
readings once overnight, but somebody fat-fingered the schedule field when setting it up.

A CronJob named `nightly-report` already exists in namespace `q103-07-cronjob-fix-schedule`.
It was meant to run **every day at 02:00**, but the schedule currently fires every minute.

Fix `nightly-report`'s `.spec.schedule` so it runs at `02:00` every day. Do not change the
container image, command, or any other field.

## Hint

Search kubernetes.io/docs for **"cronjob schedule syntax"** - the CronJob concept page shows the
five-field cron schedule format and links to the crontab syntax it follows.
