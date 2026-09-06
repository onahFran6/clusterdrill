# q105-10: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.30/#envfromsource-v1-core

```sh
kubectl delete pod payment-worker -n q105-10-secret-envfrom-prefix

kubectl apply -n q105-10-secret-envfrom-prefix -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: payment-worker
  labels:
    app: payment-worker
spec:
  containers:
    - name: payment-worker
      image: nginx:1.25-alpine
      envFrom:
        - secretRef:
            name: payment-creds
          prefix: PAY_
EOF

kubectl wait --for=condition=Ready pod/payment-worker -n q105-10-secret-envfrom-prefix --timeout=60s
```
