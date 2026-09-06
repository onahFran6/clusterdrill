# q107-15: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```sh
kubectl delete pod search-svc -n q107-15-ready-not-live-distinguish --ignore-not-found

kubectl apply -n q107-15-ready-not-live-distinguish -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: search-svc
  labels:
    app: search-svc
    clusterdrill-question: q107-15-ready-not-live-distinguish
spec:
  containers:
    - name: search-svc
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
        failureThreshold: 2
EOF

kubectl wait --for=condition=Ready pod/search-svc -n q107-15-ready-not-live-distinguish --timeout=60s
```
