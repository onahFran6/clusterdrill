# q103-09: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/

```sh
kubectl patch cronjob metrics-rollup -n q103-09-cronjob-suspend-existing \
  -p '{"spec": {"suspend": true}}'
```
