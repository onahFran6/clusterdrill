# q103-18: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/

```sh
kubectl patch cronjob data-sync -n q103-18-cronjob-fix-job-template \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/image", "value": "busybox:1.36"}]'
```
