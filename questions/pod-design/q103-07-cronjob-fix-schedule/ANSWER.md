# q103-07: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax

A single scalar field needs a strategic merge patch, not a JSON-patch array - no `op`/`path`
punctuation to get wrong for one field. `kubectl edit cronjob nightly-report` and changing the
string in place works just as well if you prefer seeing it in context.

```sh
kubectl patch cronjob nightly-report -n q103-07-cronjob-fix-schedule \
  -p '{"spec": {"schedule": "0 2 * * *"}}'
```
