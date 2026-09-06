# q107-01: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```sh
kubectl delete pod web-front -n q107-01-liveness-httpget-basic --ignore-not-found

kubectl apply -n q107-01-liveness-httpget-basic -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-front
  labels:
    app: web-front
    clusterdrill-question: q107-01-liveness-httpget-basic
spec:
  containers:
    - name: web-front
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
      livenessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 10
EOF

kubectl wait --for=condition=Ready pod/web-front -n q107-01-liveness-httpget-basic --timeout=60s
```
