# q111-07: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#canary-deployment

```sh
cat <<'EOF' | kubectl apply -n q111-07-canary-shared-service-selector -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-v2
  labels:
    clusterdrill-question: q111-07-canary-shared-service-selector
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shop
      version: v2
  template:
    metadata:
      labels:
        app: shop
        version: v2
        clusterdrill-question: q111-07-canary-shared-service-selector
    spec:
      containers:
        - name: web
          image: nginx:1.27
          ports:
            - containerPort: 80
          env:
            - name: RELEASE
              value: canary
EOF

kubectl rollout status deployment/shop-v2 -n q111-07-canary-shared-service-selector --timeout=60s

kubectl scale deployment shop-v1 -n q111-07-canary-shared-service-selector --replicas=8

kubectl set selector svc shop -n q111-07-canary-shared-service-selector 'app=shop'
```

`shop-v2`'s own selector still pins `version: v2`, so its ReplicaSet never adopts `shop-v1`'s
pods. Dropping `version` from the *Service*'s selector is what makes it match both Deployments'
pods at once - with 8 stable and 2 canary, roughly 20% of connections land on `shop-v2`. The
split is per-connection and approximate, not an exact percentage; that needs an ingress
controller's canary-weight annotation or a Gateway API traffic split, both of which need a
second Service - out of scope here since the task asks for exactly one.
