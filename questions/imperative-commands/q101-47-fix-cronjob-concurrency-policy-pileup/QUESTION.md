# q101-47-fix-cronjob-concurrency-policy-pileup: Diagnose and fix a CronJob whose runs pile up on top of each other

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-47-fix-cronjob-concurrency-policy-pileup`

`setup.sh` already created a CronJob named `log-compactor` (schedule `* * * * *`, every minute)
whose Job runs longer than one minute in namespace `q101-47-fix-cronjob-concurrency-policy-pileup`.
Run `kubectl get jobs -n q101-47-fix-cronjob-concurrency-policy-pileup` a couple of times a minute
or two apart and you'll see more than one Job from this CronJob active at once - each new scheduled
run starts before the previous one has finished.

Diagnose why using `kubectl get cronjob log-compactor -o yaml` (look at `spec.concurrencyPolicy`),
then fix it imperatively with a single `kubectl patch cronjob` command so that a new run is skipped
entirely whenever a previous run is still active, instead of starting alongside it. Do not change
the schedule or suspend the CronJob - the fix is specifically the concurrency policy.

## Hint

Search kubernetes.io/docs for **"cronjob concurrency policy"** - the CronJob concept page's
"Concurrency Policy" section documents `Allow` (the default - runs can overlap), `Forbid` (skip a
new run if the previous one hasn't finished), and `Replace`.
