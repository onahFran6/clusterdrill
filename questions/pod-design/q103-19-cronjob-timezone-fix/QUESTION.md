# q103-19: Fix a CronJob's time zone

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-19-cronjob-timezone-fix`

`setup.sh` already created a CronJob named `morning-standup-reminder` in namespace
`q103-19-cronjob-timezone-fix`. Its `.spec.schedule` is `"0 9 * * *"` - whoever wrote it meant for
the reminder to fire at **9:00 AM America/New_York** (the team's office time), but they never set
a time zone on the CronJob. Without `.spec.timeZone`, Kubernetes interprets the schedule in UTC,
so the reminder actually fires at 9:00 AM UTC - hours before anyone in the office is awake.

Fix `morning-standup-reminder` so it fires at 9:00 AM **America/New_York** time as intended, by
setting `.spec.timeZone` to the correct IANA time zone name. Do not change `.spec.schedule` - the
numeric fields (`0 9 * * *`) are already correct for local time; only the time zone interpretation
needs fixing.

## Hint

Search kubernetes.io/docs for **"cronjob time zones"** - the CronJob concept page's "Time zones"
section shows the `.spec.timeZone` field and the IANA time zone name format it expects.
