# q105-42-resourcequota-requires-explicit-resources: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/resource-quotas/#requests-vs-limits

```sh
cat > ~/worker.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: worker
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "200m"
          memory: "256Mi"
EOF

kubectl apply -n q105-42-resourcequota-requires-explicit-resources -f ~/worker.yaml

kubectl wait --for=condition=Ready pod/worker -n q105-42-resourcequota-requires-explicit-resources --timeout=60s
```
