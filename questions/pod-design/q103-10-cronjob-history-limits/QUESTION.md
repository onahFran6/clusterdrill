# q103-10: Trim how many old Job runs a CronJob keeps around

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-10-cronjob-history-limits`

`setup.sh` already created a CronJob named `audit-scan` in namespace `q103-10-cronjob-history-limits`,
running every minute. By default it keeps far more finished Jobs around than you need, cluttering
`kubectl get jobs` output.

Edit `audit-scan` so that it retains at most:

- `2` completed (successful) Jobs (`.spec.successfulJobsHistoryLimit`)
- `0` failed Jobs - failed runs should not be kept around at all (`.spec.failedJobsHistoryLimit`)

Do not change the schedule or container image.

## Hint

Search kubernetes.io/docs for **"cronjob jobs history limit"** - the CronJob concept page's "Jobs
history limits" section shows the `successfulJobsHistoryLimit` and `failedJobsHistoryLimit`
fields and their defaults.
