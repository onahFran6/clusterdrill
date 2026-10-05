# q103-11: Bound how late a missed CronJob run is allowed to start

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-11-cronjob-starting-deadline`

Orion Space Research's `stale-poll` CronJob polls a downlink relay for fresh telemetry every
minute, in namespace `q103-11-cronjob-starting-deadline`. The platform team has noticed that
when the CronJob controller itself falls behind, a missed run can still fire much later - by
then the telemetry it would fetch is already stale, so a late start is worse than no start.

Edit `stale-poll` so a missed run is only started if it can begin within **30** seconds of its
scheduled time; any later and it must count as missed. Do not change the schedule.

## Hint

Search kubernetes.io/docs for **"cronjob starting deadline"** - the CronJob concept page covers
the one spec field that bounds how late a missed schedule may still be allowed to start.
