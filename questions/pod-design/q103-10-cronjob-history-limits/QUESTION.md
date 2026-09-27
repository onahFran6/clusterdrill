# q103-10: Trim how many old Job runs a CronJob keeps around

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-10-cronjob-history-limits`

A CronJob named `audit-scan` already exists in namespace `q103-10-cronjob-history-limits`,
running every minute.

Edit `audit-scan` so that it retains at most:

- `2` completed (successful) Jobs (`.spec.successfulJobsHistoryLimit`)
- `0` failed Jobs (`.spec.failedJobsHistoryLimit`)

Do not change the schedule or container image.

## Hint

Search kubernetes.io/docs for **"cronjob jobs history limit"** - the CronJob concept page's "Jobs
history limits" section shows the `successfulJobsHistoryLimit` and `failedJobsHistoryLimit`
fields and their defaults. The defaults keep far more finished Jobs than this task allows.
