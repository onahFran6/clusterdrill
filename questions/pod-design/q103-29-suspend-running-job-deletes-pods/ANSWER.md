# q103-29: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#suspending-a-job

```sh
kubectl patch job report-builder -n q103-29-suspend-running-job-deletes-pods \
  --type merge -p '{"spec":{"suspend":true}}'
```
