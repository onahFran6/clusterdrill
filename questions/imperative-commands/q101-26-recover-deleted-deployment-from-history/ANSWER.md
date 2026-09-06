# q101-26-recover-deleted-deployment-from-history: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#how-a-replicaset-works

```sh
NS=q101-26-recover-deleted-deployment-from-history

# Inspect the orphaned ReplicaSet to recover the exact image and the full
# pod template label set.
kubectl get rs -n "$NS" -l app=catalog-svc \
  -o jsonpath='{.items[0].spec.template.metadata.labels}'
kubectl get rs -n "$NS" -l app=catalog-svc \
  -o jsonpath='{.items[0].spec.template.spec.containers[0].image}'

# Recreate the Deployment reproducing that exact pod template. If the
# recreated template differs from the orphaned ReplicaSet's in ANY way
# (an extra or missing label, different resources, etc.), the Deployment
# computes a different pod-template-hash than the orphaned RS's - it's
# still recognized as an OWNED RS by selector, but treated as an outdated
# revision and rolled over to a brand-new RS, replacing the running Pods.
# Reproducing the template exactly is what makes it adopt in place instead.
kubectl apply -n "$NS" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-svc
  labels:
    app: catalog-svc
spec:
  replicas: 3
  selector:
    matchLabels:
      app: catalog-svc
  template:
    metadata:
      labels:
        app: catalog-svc
    spec:
      containers:
        - name: catalog-svc
          image: httpd:2.4-alpine
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl rollout status deployment/catalog-svc -n "$NS" --timeout=90s
```
