# q107-45-sidecar-native-readiness-gates-main: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

Probe fields are set at container creation time and cannot be patched onto a running Pod - delete
and recreate it.

```sh
kubectl delete pod metrics-app -n q107-45-sidecar-native-readiness-gates-main --wait=true

kubectl apply -n q107-45-sidecar-native-readiness-gates-main -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: metrics-app
  labels:
    app: metrics-app
spec:
  initContainers:
    - name: metrics-sidecar
      image: nginx:1.25-alpine
      restartPolicy: Always
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
        failureThreshold: 3
  containers:
    - name: metrics-app
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/metrics-app -n q107-45-sidecar-native-readiness-gates-main --timeout=60s
```
