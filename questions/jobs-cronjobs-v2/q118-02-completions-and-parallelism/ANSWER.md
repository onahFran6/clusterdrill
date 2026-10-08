# q118-02: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-execution-for-jobs)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-02-completions-and-parallelism${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: render
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  completions: 6
  parallelism: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: render
        image: busybox:1.36
        command:
        - sh
        - -c
        - echo rendering on \$(hostname); sleep 5
YAML
kubectl wait -n "$NS" --for=condition=complete job/render --timeout=120s
kubectl get pods -n "$NS" -l job-name=render
```

The final spec proves the configured concurrency bound; a final-state grader cannot recover the highest Running count you observed during execution.
