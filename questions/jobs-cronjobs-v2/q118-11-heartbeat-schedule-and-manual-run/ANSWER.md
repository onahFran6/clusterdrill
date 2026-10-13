# q118-11: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#writing-a-cronjob-spec)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-11-heartbeat-schedule-and-manual-run${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl create cronjob heartbeat -n "$NS" --image=busybox:1.36 --schedule="*/1 * * * *" -- date
kubectl create job heartbeat-manual -n "$NS" --from=cronjob/heartbeat
kubectl wait -n "$NS" --for=condition=complete job/heartbeat-manual --timeout=120s
kubectl logs job/heartbeat-manual -n "$NS"
kubectl wait -n "$NS" --for=jsonpath='{.status.lastScheduleTime}' cronjob/heartbeat --timeout=100s
```
