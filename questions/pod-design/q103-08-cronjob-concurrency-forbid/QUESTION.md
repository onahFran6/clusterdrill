# q103-08: Stop a slow CronJob from overlapping with itself

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-08-cronjob-concurrency-forbid`

`setup.sh` already created a CronJob named `slow-sync` in namespace
`q103-08-cronjob-concurrency-forbid`. It runs every minute, and each run takes longer than a
minute to finish - so by default a new run can start while the previous one is still going,
piling up overlapping Job runs.

Edit `slow-sync` so a new run is **skipped** whenever the previous run hasn't finished yet, instead
of running concurrently. Do not change the schedule.

## Hint

Search kubernetes.io/docs for **"cronjob concurrency policy"** - the CronJob concept page's
"Concurrency Policy" section lists the three `.spec.concurrencyPolicy` values and what each one
does when a run is still active at the next scheduled time.
