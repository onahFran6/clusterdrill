# q103-12: Run a CronJob's workload right now, without waiting for its schedule

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-12-cronjob-manual-trigger`

Helix Genomics Institute's `backup-job` CronJob snapshots sequencer output once a day at
midnight (`0 0 * * *`) in namespace `q103-12-cronjob-manual-trigger`. A drive is about to be
swapped out and today's backup is needed right now, without waiting for midnight or touching
the schedule.

Create a one-off Job named `backup-job-manual` in the same namespace that runs the exact same
pod template as `backup-job`. Do not edit `backup-job`'s schedule.

## Hint

Search kubernetes.io/docs for **"kubectl create job"** - the command reference lists a flag made
specifically for spinning up a one-off Job from an existing CronJob's template, so you don't
have to retype its pod spec by hand.
