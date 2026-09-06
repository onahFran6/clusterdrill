# q103-11: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/

```sh
kubectl patch cronjob stale-poll -n q103-11-cronjob-starting-deadline \
  -p '{"spec": {"startingDeadlineSeconds": 30}}'
```
