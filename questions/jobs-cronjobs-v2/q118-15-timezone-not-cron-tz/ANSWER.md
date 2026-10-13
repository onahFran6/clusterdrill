# q118-15: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-15-timezone-not-cron-tz${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl create cronjob settle-try -n "$NS" --image=busybox:1.36 --schedule="CRON_TZ=Africa/Lagos 30 2 * * *" -- echo settling || true
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: settle
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  schedule: 30 2 * * *
  timeZone: Africa/Lagos
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: settle
            image: busybox:1.36
            command:
            - echo
            - settling
YAML
kubectl get cronjob settle -n "$NS" -o yaml
```
