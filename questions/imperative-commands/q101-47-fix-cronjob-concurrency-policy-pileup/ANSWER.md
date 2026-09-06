# q101-47-fix-cronjob-concurrency-policy-pileup: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#concurrency-policy

```sh
kubectl get cronjob log-compactor -n q101-47-fix-cronjob-concurrency-policy-pileup -o yaml
kubectl get jobs -n q101-47-fix-cronjob-concurrency-policy-pileup

kubectl patch cronjob log-compactor \
  -n q101-47-fix-cronjob-concurrency-policy-pileup \
  --type merge -p '{"spec":{"concurrencyPolicy":"Forbid"}}'
```
