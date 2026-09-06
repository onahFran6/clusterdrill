# q105-46-configmap-missing-mount-pending: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

```sh
kubectl describe pod -n q105-46-configmap-missing-mount-pending -l app=report-generator

kubectl apply -n q105-46-configmap-missing-mount-pending -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: settings-config
  labels:
    clusterdrill-question: q105-46-configmap-missing-mount-pending
data:
  MODE: "production"
EOF

kubectl rollout status deployment/report-generator -n q105-46-configmap-missing-mount-pending --timeout=60s
```
