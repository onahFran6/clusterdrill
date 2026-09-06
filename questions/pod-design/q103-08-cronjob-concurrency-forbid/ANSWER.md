# q103-08: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#concurrency-policy

```sh
kubectl patch cronjob slow-sync -n q103-08-cronjob-concurrency-forbid \
  --type='json' -p='[{"op": "add", "path": "/spec/concurrencyPolicy", "value": "Forbid"}]'
```
