# q107-06: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```sh
kubectl delete pod report-generator -n q107-06-tune-probe-timing-flaky --ignore-not-found

kubectl apply -n q107-06-tune-probe-timing-flaky -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: report-generator
  labels:
    app: report-generator
    clusterdrill-question: q107-06-tune-probe-timing-flaky
spec:
  containers:
    - name: report-generator
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 10
        failureThreshold: 3
        timeoutSeconds: 5
EOF

kubectl wait --for=condition=Ready pod/report-generator -n q107-06-tune-probe-timing-flaky --timeout=60s
```
