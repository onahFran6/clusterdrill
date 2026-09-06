# q103-12: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create_job/

```sh
kubectl create job backup-job-manual \
  --from=cronjob/backup-job \
  -n q103-12-cronjob-manual-trigger
```
