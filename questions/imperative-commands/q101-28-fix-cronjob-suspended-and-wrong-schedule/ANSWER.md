# q101-28-fix-cronjob-suspended-and-wrong-schedule: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax

```sh
kubectl patch cronjob log-rotator -n q101-28-fix-cronjob-suspended-and-wrong-schedule \
  --type='json' -p='[
    {"op": "replace", "path": "/spec/suspend", "value": false},
    {"op": "replace", "path": "/spec/schedule", "value": "*/2 * * * *"}
  ]'
```
