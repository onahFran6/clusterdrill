# q103-45: Author a CronJob that fires every 5 minutes using step-value syntax

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-45-cronjob-schedule-step-value-every-5-minutes`

`setup.sh` prepared namespace `q103-45-cronjob-schedule-step-value-every-5-minutes` but created no
workload in it yet.

Create a CronJob named `metrics-poll` that runs `busybox:1.36` with the command
`echo polling`, firing **every 5 minutes, on the 5-minute mark** (`:00`, `:05`, `:10`, ...) - not
"every 5th minute starting from whenever it happens to be created". Writing out `0,5,10,15,...,55`
by hand works but is exactly the kind of expression cron's **step value** syntax exists to avoid:
express it as a single step value on the minutes field (`*/5`), keeping every other field as `*`.

Leave `.spec.jobTemplate`'s pod template with `restartPolicy: Never`.

## Hint

Search kubernetes.io/docs for **"cronjob schedule syntax"** - the CronJob concept page's schedule
section links to the crontab format it follows, which documents step values (`*/N`) as shorthand
for "every Nth value starting from the field's minimum".
