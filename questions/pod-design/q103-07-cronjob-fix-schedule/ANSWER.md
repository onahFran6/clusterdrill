# q103-07: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax

```sh
kubectl patch cronjob nightly-report -n q103-07-cronjob-fix-schedule \
  --type='json' -p='[{"op": "replace", "path": "/spec/schedule", "value": "0 2 * * *"}]'
```
