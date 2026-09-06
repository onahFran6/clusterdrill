# q101-48-fix-job-activedeadlineseconds-premature-failure: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup

```sh
kubectl describe job/batch-migrate -n q101-48-fix-job-activedeadlineseconds-premature-failure

kubectl delete job batch-migrate -n q101-48-fix-job-activedeadlineseconds-premature-failure

kubectl apply -n q101-48-fix-job-activedeadlineseconds-premature-failure -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-migrate
  labels:
    app: batch-migrate
spec:
  activeDeadlineSeconds: 60
  backoffLimit: 2
  template:
    metadata:
      labels:
        app: batch-migrate
    spec:
      restartPolicy: Never
      containers:
        - name: batch-migrate
          image: busybox:1.36
          command: ["sh", "-c", "sleep 20 && echo migrated"]
EOF

kubectl wait --for=condition=complete job/batch-migrate \
  -n q101-48-fix-job-activedeadlineseconds-premature-failure --timeout=60s
```
