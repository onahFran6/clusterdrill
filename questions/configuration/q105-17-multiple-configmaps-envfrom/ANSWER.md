# q105-17: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.30/#envfromsource-v1-core

```sh
kubectl delete pod api-gateway -n q105-17-multiple-configmaps-envfrom

kubectl apply -n q105-17-multiple-configmaps-envfrom -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: api-gateway
  labels:
    app: api-gateway
spec:
  containers:
    - name: api-gateway
      image: nginx:1.25-alpine
      envFrom:
        - configMapRef:
            name: db-config
        - configMapRef:
            name: cache-config
EOF

kubectl wait --for=condition=Ready pod/api-gateway -n q105-17-multiple-configmaps-envfrom --timeout=60s
```
