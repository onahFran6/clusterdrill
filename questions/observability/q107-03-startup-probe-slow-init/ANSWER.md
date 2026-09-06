# q107-03: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes

```sh
kubectl delete pod legacy-monolith -n q107-03-startup-probe-slow-init --ignore-not-found

kubectl apply -n q107-03-startup-probe-slow-init -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: legacy-monolith
  labels:
    app: legacy-monolith
    clusterdrill-question: q107-03-startup-probe-slow-init
spec:
  containers:
    - name: legacy-monolith
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
        failureThreshold: 1
      startupProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 10
        failureThreshold: 9
EOF

kubectl wait --for=condition=Ready pod/legacy-monolith -n q107-03-startup-probe-slow-init --timeout=60s
```
