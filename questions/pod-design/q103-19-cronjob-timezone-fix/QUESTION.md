# q103-19: Fix a CronJob's time zone

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-19-cronjob-timezone-fix`

Spectra Observatory's `morning-standup-reminder` CronJob already exists in namespace
`q103-19-cronjob-timezone-fix`. Its `.spec.schedule` is `0 9 * * *`, meant for **9:00 AM
America/New_York**, but the reminder fires at 9:00 UTC instead - the whole team is getting
paged four to five hours early.

Fix it so the reminder actually fires at 9:00 AM **America/New_York**, without changing
`.spec.schedule` (`0 9 * * *`).

## Hint

Search kubernetes.io/docs for **"cronjob time zones"** - the CronJob concept page's "Time zones"
section shows the `.spec.timeZone` field and the IANA time zone name format it expects. Without
that field, Kubernetes reads the schedule as UTC.
