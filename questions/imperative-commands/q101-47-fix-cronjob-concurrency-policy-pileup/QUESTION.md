# q101-47: Stop a CronJob from piling up overlapping Jobs

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-47-fix-cronjob-concurrency-policy-pileup`

A CronJob named `log-compactor` (schedule `* * * * *`) already exists in namespace
`q101-47-fix-cronjob-concurrency-policy-pileup`. Its Job runs longer than one minute. Watching
`kubectl get jobs` a couple of times a minute or two apart, you'll see more than one Job from this
CronJob active at once - each new scheduled run starts before the previous one has finished.

Investigate and fix it imperatively so that a new run is skipped entirely whenever a previous run
is still active, instead of starting alongside it. Do not change the schedule or suspend the
CronJob.

## Hint

Search kubernetes.io/docs for **"cronjob concurrency policy"** - the CronJob concept page's
"Concurrency Policy" section documents `Allow` (the default - runs can overlap), `Forbid` (skip a
new run if the previous one hasn't finished), and `Replace`.
