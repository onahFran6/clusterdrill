# q101-13: Create a CronJob imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-13-create-cronjob-imperative`

In namespace `q101-13-create-cronjob-imperative`, create a CronJob named `heartbeat` that:

- runs image `busybox:1.36`
- runs the command `echo heartbeat`
- is scheduled with the cron expression `*/5 * * * *`

Use a single imperative `kubectl create cronjob` command, not a hand-written manifest.

## Hint

Search kubernetes.io/docs for **"kubectl create cronjob schedule"** - the `kubectl create
cronjob` command reference shows the `--schedule` flag and how to pass the container command
after `--`.
