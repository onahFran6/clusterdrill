# q107-07: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

```sh
kubectl wait --for=condition=Initialized pod/batch-worker -n q107-07-diagnose-crashloop-badcommand --timeout=30s || true
kubectl describe pod batch-worker -n q107-07-diagnose-crashloop-badcommand
kubectl logs batch-worker -n q107-07-diagnose-crashloop-badcommand || true

kubectl delete pod batch-worker -n q107-07-diagnose-crashloop-badcommand --ignore-not-found

kubectl apply -n q107-07-diagnose-crashloop-badcommand -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: batch-worker
  labels:
    app: batch-worker
    clusterdrill-question: q107-07-diagnose-crashloop-badcommand
spec:
  containers:
    - name: batch-worker
      image: busybox:1.36
      command: ["sh", "-c", "echo starting; sleep 3600"]
EOF

kubectl wait --for=condition=Ready pod/batch-worker -n q107-07-diagnose-crashloop-badcommand --timeout=60s
```
