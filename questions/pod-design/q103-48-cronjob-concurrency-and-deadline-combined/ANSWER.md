# q103-48: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/

**Approach A - Fastest (exam default).** None of these three fields are immutable - a CronJob's
spec is just a template, not a running workload - so a single merge patch touches exactly the
three fields asked for and leaves the schedule/image/command untouched by construction:

```sh
NS=q103-48-cronjob-concurrency-and-deadline-combined

kubectl patch cronjob ledger-close -n "$NS" --type merge -p \
  '{"spec":{"concurrencyPolicy":"Forbid","startingDeadlineSeconds":20,"jobTemplate":{"spec":{"backoffLimit":2}}}}'

kubectl get cronjob ledger-close -n "$NS" \
  -o jsonpath='concurrencyPolicy={.spec.concurrencyPolicy} startingDeadlineSeconds={.spec.startingDeadlineSeconds} backoffLimit={.spec.jobTemplate.spec.backoffLimit}{"\n"}'
```

**Approach B - Alternative.** `kubectl edit cronjob ledger-close` and change the same three
fields in vim - slower to type than the patch, but you see each field in context before saving,
which some people trust more than a one-line JSON patch:

```text
kubectl edit cronjob ledger-close -n q103-48-cronjob-concurrency-and-deadline-combined
/concurrencyPolicy<Enter>
ciwForbid<Esc>
/startingDeadlineSeconds<Enter>
$ciw20<Esc>
/backoffLimit<Enter>
$ciw2<Esc>
:wq
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - `kubectl patch` | low | low - only the named fields can change | high - the default "tweak a few fields" reflex |
| B - `kubectl edit` | medium | low - change is visible before `:wq` | high - useful when you don't trust a JSON patch path |
