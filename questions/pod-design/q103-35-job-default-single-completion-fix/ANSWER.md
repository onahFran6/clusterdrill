# q103-35: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#non-parallel-jobs

```sh
NS=q103-35-job-default-single-completion-fix

kubectl delete job onetime-cleanup -n "$NS" --wait=true

kubectl apply -n "$NS" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: onetime-cleanup
  labels:
    clusterdrill-question: $NS
spec:
  template:
    metadata:
      labels:
        clusterdrill-question: $NS
    spec:
      restartPolicy: Never
      containers:
        - name: onetime-cleanup
          image: busybox:1.36
          command: ["echo", "cleaning"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl wait --for=condition=Complete job/onetime-cleanup -n "$NS" --timeout=60s
```
