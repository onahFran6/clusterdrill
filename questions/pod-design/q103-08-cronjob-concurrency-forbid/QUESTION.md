# q103-08: Stop a slow CronJob from overlapping with itself

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-08-cronjob-concurrency-forbid`

Atlas Scientific Computing's `slow-sync` CronJob mirrors a sensor archive every minute, but each
sync now regularly takes longer than a minute to finish - and a second copy starting before the
first is done risks the two writers stepping on each other.

A CronJob named `slow-sync` already exists in namespace `q103-08-cronjob-concurrency-forbid`.
It runs every minute, and each run takes longer than a minute to finish, so a new run can start
while the previous one is still going.

Edit `slow-sync` so a new run is **skipped** whenever the previous run hasn't finished yet.
Do not change the schedule.

## Hint

Search kubernetes.io/docs for **"cronjob concurrency policy"** - the CronJob concept page's
"Concurrency Policy" section lists the three `.spec.concurrencyPolicy` values and what each one
does when a run is still active at the next scheduled time. The default lets overlapping runs
pile up.
