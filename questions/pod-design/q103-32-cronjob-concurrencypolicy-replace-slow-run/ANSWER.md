# q103-32: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#concurrency-policy

```sh
kubectl patch cronjob heavy-sync -n q103-32-cronjob-concurrencypolicy-replace-slow-run \
  --type merge -p '{"spec":{"concurrencyPolicy":"Replace"}}'
```
