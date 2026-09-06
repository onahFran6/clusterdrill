# q107-23-terminationMessage-custom-path: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/determine-reason-pod-failure/#customizing-the-termination-message

```sh
NAMESPACE="q107-23-terminationmessage-custom-path"

kubectl delete pod batch-validator -n "$NAMESPACE" --ignore-not-found --wait=true

kubectl apply -n "$NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: batch-validator
spec:
  restartPolicy: Never
  containers:
    - name: batch-validator
      image: busybox:1.36
      command: ["sh", "-c", "echo \"validation failed: schema mismatch on field age\" > /dev/termination-log; exit 1"]
      terminationMessagePath: /dev/termination-log
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Failed pod/batch-validator -n "$NAMESPACE" --timeout=60s
```
