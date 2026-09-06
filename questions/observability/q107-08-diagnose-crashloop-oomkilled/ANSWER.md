# q107-08: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/

```sh
kubectl wait --for=condition=Initialized pod/render-worker -n q107-08-diagnose-crashloop-oomkilled --timeout=30s || true
kubectl describe pod render-worker -n q107-08-diagnose-crashloop-oomkilled

kubectl delete pod render-worker -n q107-08-diagnose-crashloop-oomkilled --ignore-not-found

kubectl apply -n q107-08-diagnose-crashloop-oomkilled -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: render-worker
  labels:
    app: render-worker
    clusterdrill-question: q107-08-diagnose-crashloop-oomkilled
spec:
  containers:
    - name: render-worker
      image: polinux/stress
      command: ["stress"]
      args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
      resources:
        limits:
          memory: "256Mi"
        requests:
          memory: "256Mi"
EOF

kubectl wait --for=condition=Ready pod/render-worker -n q107-08-diagnose-crashloop-oomkilled --timeout=60s
```
