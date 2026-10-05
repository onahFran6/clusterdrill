# q103-08: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#concurrency-policy

A single scalar field needs a strategic merge patch, not a JSON-patch array - no `op`/`path`
punctuation to get wrong for one field. `kubectl edit cronjob slow-sync` and setting the value in
place works just as well if you prefer seeing it in context.

```sh
kubectl patch cronjob slow-sync -n q103-08-cronjob-concurrency-forbid \
  -p '{"spec": {"concurrencyPolicy": "Forbid"}}'
```
