# q103-06: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup

```sh
kubectl apply -n q103-06-job-active-deadline-seconds -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: long-runner
  labels:
    clusterdrill-question: q103-06-job-active-deadline-seconds
spec:
  activeDeadlineSeconds: 5
  template:
    metadata:
      labels:
        clusterdrill-question: q103-06-job-active-deadline-seconds
    spec:
      restartPolicy: Never
      containers:
        - name: long-runner
          image: busybox:1.36
          command: ["sleep", "120"]
EOF
```
