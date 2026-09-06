# q104-12: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#canary-deployment

```sh
kubectl apply -n q104-12-canary-shared-selector-split -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-canary
  labels:
    clusterdrill-question: q104-12-canary-shared-selector-split
spec:
  replicas: 1
  selector:
    matchLabels:
      app: orders
      track: canary
  template:
    metadata:
      labels:
        app: orders
        track: canary
        clusterdrill-question: q104-12-canary-shared-selector-split
    spec:
      containers:
        - name: orders
          image: nginx:1.25-alpine
EOF

kubectl rollout status deployment/orders-canary -n q104-12-canary-shared-selector-split --timeout=60s
```
