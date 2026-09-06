# q103-48: Fix a CronJob that needs three independent scheduling safeguards at once

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-48-cronjob-concurrency-and-deadline-combined`

`setup.sh` already created a CronJob named `ledger-close` in namespace
`q103-48-cronjob-concurrency-and-deadline-combined`. It runs every minute, and each
run can take longer than a minute to finish. It is a financial ledger close job with three
requirements that all matter independently - getting two out of three right is not good enough:

1. **Never run two closes at once.** A second run must never start while a previous one is still
   active - it must be skipped entirely, not queued and not left to run alongside the first
   (`.spec.concurrencyPolicy: Forbid`).
2. **Never start a close more than 20 seconds late.** If the controller is briefly down or
   overloaded and misses the exact scheduled minute, starting the close over 20 seconds late is
   worse than skipping that run entirely and waiting for the next one
   (`.spec.startingDeadlineSeconds: 20`).
3. **Give up retrying quickly.** A failed close run should not burn through the default retry
   budget - cap it at `2` retries (`.spec.jobTemplate.spec.backoffLimit: 2`).

Right now `ledger-close` has none of these three set correctly (check its current values). Edit it
so all three fields have exactly the values above, without changing the schedule, image, or
command.

## Hint

Search kubernetes.io/docs for **"cronjob concurrency policy"** - the CronJob concept page covers
`concurrencyPolicy` and `startingDeadlineSeconds` together, and links to the Jobs concept page for
`backoffLimit` on the `jobTemplate.spec` it embeds.
