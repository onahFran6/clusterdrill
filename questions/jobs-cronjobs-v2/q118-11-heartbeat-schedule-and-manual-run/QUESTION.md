# q118-11: Schedule a heartbeat and test it immediately

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-11-heartbeat-schedule-and-manual-run`

Team Io needs *CronJob* `heartbeat` using `busybox:1.36` and `date` every minute.
Run it immediately as *Job* `heartbeat-manual` without waiting for the schedule and read its date log.
Also wait for a real scheduled run and confirm the CronJob recorded its last schedule time.

## Hint

Search kubernetes.io/docs for "create Job from CronJob" and CronJob status.
