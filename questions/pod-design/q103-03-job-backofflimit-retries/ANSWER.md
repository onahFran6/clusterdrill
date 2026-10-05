# q103-03: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy

A single scalar field needs a strategic merge patch, not a JSON-patch array - no `op`/`path`
punctuation to get wrong for one field. `kubectl edit job flaky-task` and changing the number in
place works just as well if you prefer seeing it in context.

```sh
kubectl patch job flaky-task -n q103-03-job-backofflimit-retries \
  -p '{"spec": {"backoffLimit": 2}}'
```
