# q103-01: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#controlling-parallelism

```sh
kubectl apply -n q103-01-job-fixed-completions -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: digest-batch
  labels:
    clusterdrill-question: q103-01-job-fixed-completions
spec:
  completions: 6
  template:
    metadata:
      labels:
        clusterdrill-question: q103-01-job-fixed-completions
    spec:
      restartPolicy: Never
      containers:
        - name: digest-batch
          image: busybox:1.36
          command: ["sha256sum", "/etc/hostname"]
EOF
```
