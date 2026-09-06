# q104-01: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment

```sh
kubectl apply -n q104-01-create-deployment-strategy -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
  labels:
    clusterdrill-question: q104-01-create-deployment-strategy
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: checkout
  template:
    metadata:
      labels:
        app: checkout
        clusterdrill-question: q104-01-create-deployment-strategy
    spec:
      containers:
        - name: checkout
          image: nginx:1.25-alpine
EOF

kubectl rollout status deployment/checkout -n q104-01-create-deployment-strategy --timeout=60s
```
