# q105-48-limitrange-type-pod-aggregate: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/limit-range/

```sh
cat > ~/multi-app.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: multi-app
spec:
  containers:
    - name: primary
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: "250m"
          memory: "256Mi"
        limits:
          cpu: "250m"
          memory: "256Mi"
    - name: helper
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: "250m"
          memory: "256Mi"
        limits:
          cpu: "250m"
          memory: "256Mi"
EOF

kubectl apply -n q105-48-limitrange-type-pod-aggregate -f ~/multi-app.yaml

kubectl wait --for=condition=Ready pod/multi-app -n q105-48-limitrange-type-pod-aggregate --timeout=60s
```
