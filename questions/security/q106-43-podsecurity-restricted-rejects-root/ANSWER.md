# q106-43-podsecurity-restricted-rejects-root: reference solution

Doc: https://kubernetes.io/docs/concepts/security/pod-security-standards/

```sh
kubectl apply -n q106-43-podsecurity-restricted-rejects-root -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: audit-runner
  labels:
    app: audit-runner
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: audit-runner
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/audit-runner -n q106-43-podsecurity-restricted-rejects-root --timeout=60s
```
