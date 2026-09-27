# q103-19: Fix a CronJob's time zone

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-19-cronjob-timezone-fix`

A CronJob named `morning-standup-reminder` already exists in namespace
`q103-19-cronjob-timezone-fix`. Its `.spec.schedule` is `0 9 * * *`, meant for **9:00 AM
America/New_York**, but the reminder fires at 9:00 UTC.

Set `.spec.timeZone` so it fires at 9:00 AM **America/New_York**. Do not change `.spec.schedule`
(`0 9 * * *`).

## Hint

Search kubernetes.io/docs for **"cronjob time zones"** - the CronJob concept page's "Time zones"
section shows the `.spec.timeZone` field and the IANA time zone name format it expects. Without
that field, Kubernetes reads the schedule as UTC.
