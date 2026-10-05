# q103-48: Fix a CronJob that needs three independent scheduling safeguards at once

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-48-cronjob-concurrency-and-deadline-combined`

Catalyst Research Institute's `ledger-close` CronJob reconciles the previous minute's instrument
readings, in namespace `q103-48-cronjob-concurrency-and-deadline-combined`. It runs every
minute, and a run can take longer than a minute to finish. Right now it has none of the
safeguards this needs:

1. A second run must never start while a previous run is still active - it should simply be
   skipped, not queued alongside it and not used to kill the one already running.
2. A run that's missed its scheduled time must not be allowed to start if it's more than **20**
   seconds late.
3. A run that fails should retry at most **2** times before giving up.

Edit `ledger-close` so all three safeguards are in place. Do not change the schedule, image, or
command.

## Hint

Search kubernetes.io/docs for **"cronjob concurrency policy"** - the CronJob concept page covers
the field with three possible values for handling an overlapping run, plus a separate field for
how late a missed run may start; the Jobs concept page covers the retry-limit field on the
embedded `jobTemplate.spec`.
