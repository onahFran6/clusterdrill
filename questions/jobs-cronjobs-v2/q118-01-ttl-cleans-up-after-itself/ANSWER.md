# q118-01: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/#ttl-mechanism-for-finished-jobs)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-01-ttl-cleans-up-after-itself${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: stamp
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  ttlSecondsAfterFinished: 60
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: stamp
        image: busybox:1.36
        command:
        - sh
        - -c
        - date; hostname
YAML
kubectl wait -n "$NS" --for=condition=complete job/stamp --timeout=120s
kubectl logs job/stamp -n "$NS"
```

The 60-second TTL deletes both the Job and its Pods, including their logs.
Grade promptly after completion; after deletion, reset and recreate the Job to grade again.
The reference deliberately stops before cleanup.
