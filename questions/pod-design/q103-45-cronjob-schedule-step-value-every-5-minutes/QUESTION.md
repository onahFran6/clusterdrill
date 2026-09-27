# q103-45: Author a CronJob that fires every 5 minutes using step-value syntax

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-45-cronjob-schedule-step-value-every-5-minutes`

Namespace `q103-45-cronjob-schedule-step-value-every-5-minutes` exists and has no workload yet.

Create a CronJob named `metrics-poll` that runs `busybox:1.36` with the command `echo polling`
on schedule `*/5 * * * *` (every 5 minutes: `:00`, `:05`, `:10`, and so on).

Leave the pod template `restartPolicy: Never`.

## Hint

Search kubernetes.io/docs for **"cronjob schedule syntax"** - the CronJob concept page's schedule
section links to the crontab format, which documents step values (`*/N`) as shorthand for every
Nth value from the field's minimum. Listing `0,5,10,15,...,55` is the same minutes, written out.
