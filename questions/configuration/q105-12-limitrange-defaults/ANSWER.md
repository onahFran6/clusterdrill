# q105-12: reference solution

Doc: https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/

```sh
kubectl apply -n q105-12-limitrange-defaults -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: container-defaults
spec:
  limits:
    - type: Container
      default:
        cpu: "200m"
        memory: "256Mi"
      defaultRequest:
        cpu: "100m"
        memory: "128Mi"
EOF

kubectl apply -n q105-12-limitrange-defaults -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: plain-app
  labels:
    app: plain-app
spec:
  containers:
    - name: plain-app
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/plain-app -n q105-12-limitrange-defaults --timeout=60s
```
