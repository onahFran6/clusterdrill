# q118-13: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#jobs-history-limits)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-13-history-limits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl patch cronjob ping -n "$NS" --type=merge -p '{"spec":{"successfulJobsHistoryLimit":2,"failedJobsHistoryLimit":1}}'
sleep 240
kubectl get jobs -n "$NS"
```

History limits count finished Jobs, not active Jobs.
The grader selects Jobs by CronJob owner reference and polls through controller cleanup; an exact total of two Jobs is not stable at a scheduling boundary.
