# q107-32-readiness-successthreshold-recovery: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

`readinessProbe` fields are set at container creation time and cannot be patched onto a running
Pod - delete and recreate it.

```sh
kubectl delete pod flaky-backend -n q107-32-readiness-successthreshold-recovery --wait=true

kubectl apply -n q107-32-readiness-successthreshold-recovery -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: flaky-backend
  labels:
    app: flaky-backend
spec:
  containers:
    - name: flaky-backend
      image: nginx:1.25-alpine
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
        successThreshold: 3
EOF

kubectl wait --for=condition=Ready pod/flaky-backend -n q107-32-readiness-successthreshold-recovery --timeout=60s
```
