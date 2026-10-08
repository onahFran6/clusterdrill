# q118-12: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#concurrency-policy)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-12-forbid-stops-overlap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl patch cronjob sync -n "$NS" --type=merge -p '{"spec":{"concurrencyPolicy":"Forbid"}}'
kubectl delete jobs --all -n "$NS"
sleep 180
kubectl get cronjob sync -n "$NS"
```
