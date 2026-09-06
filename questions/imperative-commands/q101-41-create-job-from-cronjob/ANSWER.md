# q101-41-create-job-from-cronjob: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-job-limitations

```sh
kubectl create job manual-report-run \
  -n q101-41-create-job-from-cronjob \
  --from=cronjob/nightly-report

kubectl wait --for=condition=complete job/manual-report-run \
  -n q101-41-create-job-from-cronjob --timeout=60s
```
