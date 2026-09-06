# q103-19: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones

```sh
kubectl patch cronjob morning-standup-reminder -n q103-19-cronjob-timezone-fix \
  --type='json' -p='[{"op": "add", "path": "/spec/timeZone", "value": "America/New_York"}]'
```
