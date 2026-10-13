# q118-05: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/#completion-mode)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-05-indexed-job-shards${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: shard-worker
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  completions: 3
  parallelism: 3
  completionMode: Indexed
  template:
    spec:
      restartPolicy: Never
      volumes:
      - name: shards
        configMap:
          name: shards
      containers:
      - name: worker
        image: busybox:1.36
        command:
        - sh
        - -c
        - 'echo shard \$JOB_COMPLETION_INDEX: \$(cat /shards/\$JOB_COMPLETION_INDEX)'
        volumeMounts:
        - name: shards
          mountPath: /shards
YAML
kubectl wait -n "$NS" --for=condition=complete job/shard-worker --timeout=120s
kubectl logs job/shard-worker -n "$NS"
```

Indexed completion prevents two successful completions from counting for the same index.
It does not guarantee the application runs exactly once; retries can repeat processing, so real workers still need idempotency.
