# q103-27: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup

```sh
kubectl patch job stubborn-retrier -n q103-27-job-activedeadline-interrupts-backoff \
  --type='json' -p='[{"op": "replace", "path": "/spec/activeDeadlineSeconds", "value": 25}]'
```
