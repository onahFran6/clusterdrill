# q106-39-allowprivilegeescalation-false: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container

`allowPrivilegeEscalation` is set at container creation time and cannot be patched onto a running
Pod - delete and recreate it.

```sh
kubectl delete pod web-worker -n q106-39-allowprivilegeescalation-false --wait=true

kubectl apply -n q106-39-allowprivilegeescalation-false -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-worker
  labels:
    app: web-worker
spec:
  containers:
    - name: web-worker
      image: nginx:1.25-alpine
      securityContext:
        allowPrivilegeEscalation: false
EOF

kubectl wait --for=condition=Ready pod/web-worker -n q106-39-allowprivilegeescalation-false --timeout=60s
```
