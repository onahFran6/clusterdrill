# q103-09: Pause a CronJob without deleting it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-09-cronjob-suspend-existing`

Entropy Research Systems needs a maintenance window on its metrics pipeline tonight.
`metrics-rollup` must stop firing new runs for now, but nobody wants to rebuild its
configuration from scratch once the window closes.

A CronJob named `metrics-rollup` already exists in namespace `q103-09-cronjob-suspend-existing`,
scheduled to run every minute. Pause it for a maintenance window without losing its
configuration, so it can be turned back on later.

Suspend `metrics-rollup` so the schedule stops triggering new Job runs, without deleting the
CronJob itself.

## Hint

Search kubernetes.io/docs for **"cronjob suspend"** - the CronJob concept page's "CronJob
limitations" / suspend section shows the `.spec.suspend` field and how to set it with `kubectl
patch`.
