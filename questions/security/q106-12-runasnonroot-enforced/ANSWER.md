# q106-12: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
kubectl apply -n q106-12-runasnonroot-enforced -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: hardened-app
spec:
  securityContext:
    runAsNonRoot: true
  containers:
    - name: hardened-app
      image: nginxinc/nginx-unprivileged:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/hardened-app -n q106-12-runasnonroot-enforced --timeout=60s
```
