# q103-24: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-failure-policy

`.spec.podFailurePolicy` is immutable once a Job is created, so both Jobs must be deleted and
recreated with the corrected policy rather than patched in place.

```sh
NS=q103-24-job-podfailurepolicy-ignore-exit-code

kubectl delete job code42-loader flaky-loader -n "$NS" --wait=true

# code42-loader: exit code 42 now fails the Job immediately instead of
# retrying - same image/command/backoffLimit as before, only
# podFailurePolicy is added.
kubectl apply -n "$NS" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: code42-loader
  labels:
    clusterdrill-question: $NS
spec:
  backoffLimit: 4
  podFailurePolicy:
    rules:
      - action: FailJob
        onExitCodes:
          containerName: loader
          operator: In
          values: [42]
  template:
    metadata:
      labels:
        clusterdrill-question: $NS
    spec:
      restartPolicy: Never
      containers:
        - name: loader
          image: busybox:1.36
          command: ["sh", "-c", "exit 42"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

# flaky-loader: the SAME rule shape (only exit code 42 -> FailJob) - since
# this container never exits 42, the rule simply never matches, so its
# actual non-42 failures fall through to Kubernetes' default pod-failure
# counting and retry normally up to backoffLimit, same as before this fix.
kubectl apply -n "$NS" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: flaky-loader
  labels:
    clusterdrill-question: $NS
spec:
  backoffLimit: 2
  podFailurePolicy:
    rules:
      - action: FailJob
        onExitCodes:
          containerName: loader
          operator: In
          values: [42]
  template:
    metadata:
      labels:
        clusterdrill-question: $NS
    spec:
      restartPolicy: Never
      containers:
        - name: loader
          image: busybox:1.36
          command: ["sh", "-c", "exit 7"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF
```
