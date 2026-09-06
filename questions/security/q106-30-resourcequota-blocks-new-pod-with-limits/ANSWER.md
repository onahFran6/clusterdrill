# q106-30-resourcequota-blocks-new-pod-with-limits: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/resource-quotas/#requests-vs-limits

```sh
kubectl apply -n q106-30-resourcequota-blocks-new-pod-with-limits -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-worker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: new-worker
  template:
    metadata:
      labels:
        app: new-worker
    spec:
      containers:
        - name: nginx
          image: nginx:1.25-alpine
          resources:
            requests:
              cpu: "100m"
              memory: "56Mi"
EOF

kubectl rollout status deployment/new-worker \
  -n q106-30-resourcequota-blocks-new-pod-with-limits --timeout=60s
```
