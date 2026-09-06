# q107-02: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```sh
kubectl delete pod catalog-api -n q107-02-readiness-httpget-basic --ignore-not-found

kubectl apply -n q107-02-readiness-httpget-basic -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: catalog-api
  labels:
    app: catalog-api
    clusterdrill-question: q107-02-readiness-httpget-basic
spec:
  containers:
    - name: catalog-api
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
        failureThreshold: 3
EOF

kubectl wait --for=condition=Ready pod/catalog-api -n q107-02-readiness-httpget-basic --timeout=60s
```
