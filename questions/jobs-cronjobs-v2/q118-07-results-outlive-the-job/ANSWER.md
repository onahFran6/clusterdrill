# q118-07: reference solution

Doc: [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/#ttl-mechanism-for-finished-jobs)

The commands below show the complete manifest so the reference can run without an interactive editor.
When practicing, scaffold a Job or CronJob with `--dry-run=client -o yaml`, then edit the required fields.

```sh
set -euo pipefail
NS="q118-07-results-outlive-the-job${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: results
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
---
apiVersion: batch/v1
kind: Job
metadata:
  name: calc
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  ttlSecondsAfterFinished: 30
  template:
    spec:
      restartPolicy: Never
      volumes:
      - name: results
        persistentVolumeClaim:
          claimName: results
      containers:
      - name: calc
        image: busybox:1.36
        command:
        - sh
        - -c
        - echo total=\$((6*7)) > /results/latest.txt
        volumeMounts:
        - name: results
          mountPath: /results
YAML
kubectl wait -n "$NS" --for=condition=complete job/calc --timeout=120s
kubectl wait -n "$NS" --for=delete job/calc --timeout=120s
kubectl apply -n "$NS" -f - <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: dashboard
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  restartPolicy: Never
  volumes:
  - name: results
    persistentVolumeClaim:
      claimName: results
  containers:
  - name: dashboard
    image: busybox:1.36
    command:
    - cat
    - /results/latest.txt
    volumeMounts:
    - name: results
      mountPath: /results
YAML
kubectl wait -n "$NS" --for=jsonpath='{.status.phase}'=Succeeded pod/dashboard --timeout=120s
kubectl logs dashboard -n "$NS"
```

The Job no longer exists at grading time, so the literal TTL cannot be recovered.
Grading checks durable absence and the reader Pod mounting the bound claim; the automatic deletion sequence is a practice requirement.
Deleting the Job manually produces the same observable final state, which the grader cannot distinguish.
