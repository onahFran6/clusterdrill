# q103-05: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-patterns

```sh
kubectl apply -n q103-05-job-work-queue-parallelism -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: queue-workers
  labels:
    clusterdrill-question: q103-05-job-work-queue-parallelism
spec:
  parallelism: 4
  template:
    metadata:
      labels:
        clusterdrill-question: q103-05-job-work-queue-parallelism
    spec:
      restartPolicy: Never
      containers:
        - name: queue-workers
          image: busybox:1.36
          command: ["sh", "-c", "sleep 2 && exit 0"]
EOF
```
