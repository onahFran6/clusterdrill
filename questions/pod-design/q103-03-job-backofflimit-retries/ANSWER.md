# q103-03: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy

```sh
kubectl patch job flaky-task -n q103-03-job-backofflimit-retries \
  --type='json' -p='[{"op": "replace", "path": "/spec/backoffLimit", "value": 2}]'
```
