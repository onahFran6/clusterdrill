# q118-09: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-failure-policy)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-09-pod-failure-policy-skips-pointless-retries${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: validate
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  backoffLimit: 4
  podFailurePolicy:
    rules:
    - action: FailJob
      onExitCodes:
        containerName: validate
        operator: In
        values:
        - 3
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: validate
        image: busybox:1.36
        command:
        - sh
        - -c
        - echo invalid input; exit 3
YAML
kubectl wait -n "$NS" --for=condition=failed job/validate --timeout=120s
kubectl describe job validate -n "$NS"
```
