# q107-43-readinessprobe-httpget-custom-header: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-http-request

`readinessProbe` fields are set at container creation time and cannot be patched onto a running
Pod - delete and recreate it.

```sh
kubectl delete pod api-gateway -n q107-43-readinessprobe-httpget-custom-header --wait=true

kubectl apply -n q107-43-readinessprobe-httpget-custom-header -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: api-gateway
  labels:
    app: api-gateway
spec:
  containers:
    - name: api-gateway
      image: nginx:1.25-alpine
      readinessProbe:
        httpGet:
          path: /
          port: 80
          httpHeaders:
            - name: X-Probe-Source
              value: kubelet
        periodSeconds: 2
EOF

kubectl wait --for=condition=Ready pod/api-gateway -n q107-43-readinessprobe-httpget-custom-header --timeout=60s
```
