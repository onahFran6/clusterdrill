# q105-11: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/

```sh
kubectl apply -n q105-11-resource-requests-limits -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: batch-worker
  labels:
    app: batch-worker
spec:
  containers:
    - name: batch-worker
      image: nginx:1.25-alpine
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "250m"
          memory: "256Mi"
EOF

kubectl wait --for=condition=Ready pod/batch-worker -n q105-11-resource-requests-limits --timeout=60s
```
