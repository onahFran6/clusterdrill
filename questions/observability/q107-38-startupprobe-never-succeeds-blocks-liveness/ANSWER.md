# q107-38-startupprobe-never-succeeds-blocks-liveness: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes

Probe fields are set at container creation time and cannot be patched onto a running Pod - delete
and recreate it.

```sh
kubectl delete pod slow-starter -n q107-38-startupprobe-never-succeeds-blocks-liveness --wait=true

kubectl apply -n q107-38-startupprobe-never-succeeds-blocks-liveness -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: slow-starter
  labels:
    app: slow-starter
spec:
  containers:
    - name: slow-starter
      image: nginx:1.25-alpine
      startupProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
        failureThreshold: 100
      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
EOF

kubectl wait --for=condition=Ready pod/slow-starter -n q107-38-startupprobe-never-succeeds-blocks-liveness --timeout=60s
```
