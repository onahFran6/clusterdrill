# q103-09: Pause a CronJob without deleting it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-09-cronjob-suspend-existing`

`setup.sh` already created a CronJob named `metrics-rollup` in namespace
`q103-09-cronjob-suspend-existing`, scheduled to run every minute. A teammate asked you to pause it
during a maintenance window without losing its configuration, so it can be turned back on later.

Suspend `metrics-rollup` so the schedule stops triggering new Job runs, without deleting the
CronJob itself.

## Hint

Search kubernetes.io/docs for **"cronjob suspend"** - the CronJob concept page's "CronJob
limitations" / suspend section shows the `.spec.suspend` field and how to set it with `kubectl
patch`.
