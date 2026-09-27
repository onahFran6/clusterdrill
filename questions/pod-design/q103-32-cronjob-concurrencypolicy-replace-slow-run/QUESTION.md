# q103-32: Replace an in-flight CronJob run instead of skipping or stacking it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-32-cronjob-concurrencypolicy-replace-slow-run`

A CronJob named `heavy-sync` already exists in namespace
`q103-32-cronjob-concurrencypolicy-replace-slow-run`. It runs every minute, and each run takes
longer than a minute, so a new run can start while the previous one is still active.

A stale run must not keep going once a newer one is due, and the new run must not be skipped.

Edit `heavy-sync` so that when a new scheduled time arrives while a previous run is still active,
the previous Job is replaced by the new one. Do not change the schedule.

## Hint

Search kubernetes.io/docs for **"cronjob concurrency policy"** - the CronJob concept page's
"Concurrency Policy" section lists all three `.spec.concurrencyPolicy` values, including the one
that terminates the currently running job and replaces it. Unset means `Allow`, which lets a
second Job start beside the first. `Forbid` would skip the new run instead.
