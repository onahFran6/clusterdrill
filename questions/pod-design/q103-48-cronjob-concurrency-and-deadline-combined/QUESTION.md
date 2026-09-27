# q103-48: Fix a CronJob that needs three independent scheduling safeguards at once

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-48-cronjob-concurrency-and-deadline-combined`

A CronJob named `ledger-close` already exists in namespace
`q103-48-cronjob-concurrency-and-deadline-combined`. It runs every minute, and a run can take
longer than a minute. None of these three fields is set to the required value:

1. `.spec.concurrencyPolicy: Forbid` - a second run must not start while a previous one is still
   active.
2. `.spec.startingDeadlineSeconds: 20` - a missed run must not start more than `20` seconds late.
3. `.spec.jobTemplate.spec.backoffLimit: 2` - a failed run retries at most `2` times.

Edit `ledger-close` so all three fields have exactly those values. Do not change the schedule,
image, or command.

## Hint

Search kubernetes.io/docs for **"cronjob concurrency policy"** - the CronJob concept page covers
`concurrencyPolicy` and `startingDeadlineSeconds`, and the Jobs concept page covers
`backoffLimit` on the embedded `jobTemplate.spec`. `Forbid` skips the new run. `Allow` would
start it beside the current one, and `Replace` would kill the current one.
