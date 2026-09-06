# q103-10: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#jobs-history-limits

```sh
kubectl patch cronjob audit-scan -n q103-10-cronjob-history-limits \
  -p '{"spec": {"successfulJobsHistoryLimit": 2, "failedJobsHistoryLimit": 0}}'
```
