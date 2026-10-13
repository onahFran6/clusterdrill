# q118-15: Run settlement at Lagos local time

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-15-timezone-not-cron-tz`

Team Callisto needs *CronJob* `settle` using `busybox:1.36` and `echo settling` at **02:30 Lagos time** daily, independent of the controller time zone.
First try creating `settle-try` with schedule `CRON_TZ=Africa/Lagos 30 2 * * *` and read the rejection (practice observation, ungraded).
Create `settle` correctly and inspect its schedule and time zone.

## Hint

Search kubernetes.io/docs for "CronJob time zones" and where an IANA zone belongs.
