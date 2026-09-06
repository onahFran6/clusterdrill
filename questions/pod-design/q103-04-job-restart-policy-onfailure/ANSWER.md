# q103-04: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-template

```sh
kubectl apply -n q103-04-job-restart-policy-onfailure -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: retry-in-place
  labels:
    clusterdrill-question: q103-04-job-restart-policy-onfailure
spec:
  backoffLimit: 3
  template:
    metadata:
      labels:
        clusterdrill-question: q103-04-job-restart-policy-onfailure
    spec:
      restartPolicy: OnFailure
      containers:
        - name: retry-in-place
          image: busybox:1.36
          command: ["sh", "-c", "exit 1"]
EOF
```
