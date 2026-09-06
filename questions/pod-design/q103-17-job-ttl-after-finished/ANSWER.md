# q103-17: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#clean-up-finished-jobs-automatically

```sh
kubectl apply -n q103-17-job-ttl-after-finished -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: self-cleaning
  labels:
    clusterdrill-question: q103-17-job-ttl-after-finished
spec:
  ttlSecondsAfterFinished: 10
  template:
    metadata:
      labels:
        clusterdrill-question: q103-17-job-ttl-after-finished
    spec:
      restartPolicy: Never
      containers:
        - name: self-cleaning
          image: busybox:1.36
          command: ["echo", "done"]
EOF
```
