# q118-04: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-04-hard-deadline-beats-retries${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: report
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  activeDeadlineSeconds: 20
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: report
        image: busybox:1.36
        command:
        - sleep
        - '300'
YAML
kubectl wait -n "$NS" --for=condition=failed job/report --timeout=90s
kubectl describe job report -n "$NS"
```

The Job-level deadline limits total execution time, including retries.
The controller terminates active Pods; retention of their objects is not a portable final-state requirement.
