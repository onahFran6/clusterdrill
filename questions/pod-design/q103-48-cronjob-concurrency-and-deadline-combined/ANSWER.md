# q103-48: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/

```sh
kubectl patch cronjob ledger-close -n q103-48-cronjob-concurrency-and-deadline-combined \
  --type merge -p '{
    "spec": {
      "concurrencyPolicy": "Forbid",
      "startingDeadlineSeconds": 20,
      "jobTemplate": {
        "spec": {
          "backoffLimit": 2
        }
      }
    }
  }'
```
