# q103-02: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs

```sh
kubectl apply -n q103-02-job-parallelism-fanout -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: render-fanout
  labels:
    clusterdrill-question: q103-02-job-parallelism-fanout
spec:
  completions: 9
  parallelism: 3
  template:
    metadata:
      labels:
        clusterdrill-question: q103-02-job-parallelism-fanout
    spec:
      restartPolicy: Never
      containers:
        - name: render-fanout
          image: busybox:1.36
          command: ["sleep", "3"]
EOF
```
