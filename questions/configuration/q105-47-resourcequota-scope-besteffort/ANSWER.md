# q105-47-resourcequota-scope-besteffort: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/resource-quotas/#resource-quota-scopes

```sh
cat > ~/extra-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: extra-worker
spec:
  containers:
    - name: extra-worker
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: "50m"
          memory: "64Mi"
        limits:
          cpu: "100m"
          memory: "128Mi"
EOF

kubectl apply -n q105-47-resourcequota-scope-besteffort -f ~/extra-pod.yaml

kubectl wait --for=condition=Ready pod/extra-worker -n q105-47-resourcequota-scope-besteffort --timeout=60s
```
