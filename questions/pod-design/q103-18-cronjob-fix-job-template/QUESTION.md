# q103-18: Fix a CronJob whose Job template can never run

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-18-cronjob-fix-job-template`

`setup.sh` already created a CronJob named `data-sync` in namespace
`q103-18-cronjob-fix-job-template`, scheduled every minute. Every run of it fails immediately
because whoever wrote it used a container image that doesn't exist: `busybox:this-tag-does-not-exist`.

Fix `data-sync`'s `jobTemplate` so its container uses image `busybox:1.36` instead, keeping the
same command (`echo syncing`). Do not change the schedule or the CronJob's name.

## Hint

Search kubernetes.io/docs for **"cronjob job template"** - the CronJob concept page shows that
`.spec.jobTemplate` holds the same Job spec you'd write for a standalone Job, so fixing it is the
same as fixing any Job's pod template.
