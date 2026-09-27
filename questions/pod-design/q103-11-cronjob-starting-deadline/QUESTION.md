# q103-11: Bound how late a missed CronJob run is allowed to start

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-11-cronjob-starting-deadline`

A CronJob named `stale-poll` already exists in namespace `q103-11-cronjob-starting-deadline`,
scheduled every minute. A missed scheduled time can still start late.

Edit `stale-poll` so a missed run is only started if it can begin within `30` seconds of its
scheduled time (`.spec.startingDeadlineSeconds: 30`). Later than that, it counts as missed.
Do not change the schedule.

## Hint

Search kubernetes.io/docs for **"cronjob starting deadline seconds"** - the CronJob concept page
covers `.spec.startingDeadlineSeconds` and how it bounds how late a missed schedule may still
start. Without that bound, a controller blip still starts the missed run no matter how late.
