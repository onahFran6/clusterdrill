# q105-07: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#define-container-environment-variables-using-configmap-data

```sh
kubectl delete pod storefront -n q105-07-configmap-key-env-var

kubectl apply -n q105-07-configmap-key-env-var -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: storefront
  labels:
    app: storefront
spec:
  containers:
    - name: storefront
      image: nginx:1.25-alpine
      env:
        - name: CHECKOUT_FLAG
          valueFrom:
            configMapKeyRef:
              name: feature-flags
              key: NEW_CHECKOUT
EOF

kubectl wait --for=condition=Ready pod/storefront -n q105-07-configmap-key-env-var --timeout=60s
```
