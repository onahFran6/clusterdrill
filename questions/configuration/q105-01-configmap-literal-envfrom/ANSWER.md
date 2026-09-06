# q105-01: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#configure-all-key-value-pairs-in-a-configmap-as-container-environment-variables

```sh
kubectl create configmap catalog-env \
  --from-literal=CATALOG_MODE=readonly \
  --from-literal=CATALOG_REGION=eu-west-1 \
  -n q105-01-configmap-literal-envfrom

kubectl delete pod catalog-app -n q105-01-configmap-literal-envfrom

kubectl apply -n q105-01-configmap-literal-envfrom -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: catalog-app
  labels:
    app: catalog-app
spec:
  containers:
    - name: catalog-app
      image: nginx:1.25-alpine
      envFrom:
        - configMapRef:
            name: catalog-env
EOF

kubectl wait --for=condition=Ready pod/catalog-app -n q105-01-configmap-literal-envfrom --timeout=60s
```
