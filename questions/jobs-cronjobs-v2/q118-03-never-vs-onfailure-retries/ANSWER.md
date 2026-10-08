# q118-03: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-03-never-vs-onfailure-retries${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: import-never
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  backoffLimit: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: import-never
        image: busybox:1.36
        command:
        - sh
        - -c
        - echo importing; exit 1
---
apiVersion: batch/v1
kind: Job
metadata:
  name: import-onfailure
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  backoffLimit: 2
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: import-never
        image: busybox:1.36
        command:
        - sh
        - -c
        - echo importing; exit 1
YAML
kubectl wait -n "$NS" --for=condition=failed job/import-never --timeout=240s
kubectl wait -n "$NS" --for=condition=failed job/import-onfailure --timeout=240s
kubectl get jobs,pods -n "$NS"
```

Never normally leaves three failed Pods for this workload.
With OnFailure, the kubelet restarts the container in place, and the Job controller may delete the Pod when the restart budget is exhausted.
A retained restart counter is therefore a practice observation, not a durable grading requirement.
