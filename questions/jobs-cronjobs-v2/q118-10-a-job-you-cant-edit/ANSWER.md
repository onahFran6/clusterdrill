# q118-10: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/#suspending-a-job)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-10-a-job-you-cant-edit${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl get pods -n "$NS" -l job-name=export
kubectl set image job/export export=busybox:1.36 -n "$NS" || true
kubectl delete job export -n "$NS"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: export
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  suspend: true
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: export
        image: busybox:1.36
        command:
        - echo
        - exporting
YAML
kubectl patch job export -n "$NS" --type=merge -p '{"spec":{"suspend":false}}'
kubectl wait -n "$NS" --for=condition=complete job/export --timeout=120s
```

The completed Job proves the corrected image and final resumed state.
Its earlier suspended state and the failed edit attempt cannot be reconstructed from final state.
