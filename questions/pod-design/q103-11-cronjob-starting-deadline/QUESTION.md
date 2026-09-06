# q103-11: Bound how late a missed CronJob run is allowed to start

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-11-cronjob-starting-deadline`

`setup.sh` already created a CronJob named `stale-poll` in namespace
`q103-11-cronjob-starting-deadline`, scheduled every minute. If the controller is briefly down or
overloaded and misses a scheduled time, by default it will still start that run late, no matter
how late.

Edit `stale-poll` so a missed run is only started if it can begin within `30` seconds of its
scheduled time - if it's later than that, Kubernetes should count it as a missed run instead of
starting it late (`.spec.startingDeadlineSeconds: 30`). Do not change the schedule.

## Hint

Search kubernetes.io/docs for **"cronjob starting deadline seconds"** - the CronJob concept page
covers `.spec.startingDeadlineSeconds` and how it bounds how late a missed schedule may still
start.
