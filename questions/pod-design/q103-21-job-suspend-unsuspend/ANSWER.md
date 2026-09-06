# q103-21: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#suspending-a-job

```sh
kubectl patch job archive-purge -n q103-21-job-suspend-unsuspend \
  -p '{"spec": {"suspend": false}}'
```
