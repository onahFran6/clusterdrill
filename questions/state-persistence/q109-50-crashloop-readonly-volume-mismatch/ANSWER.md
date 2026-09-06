# q109-50-crashloop-readonly-volume-mismatch: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

Volume fields cannot be patched on a running Pod - delete and recreate it.

```sh
kubectl delete pod session-tracker -n q109-50-crashloop-readonly-volume-mismatch --wait=true

kubectl apply -n q109-50-crashloop-readonly-volume-mismatch -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: session-tracker
spec:
  containers:
    - name: session-tracker
      image: busybox:1.36
      command: ["sh", "-c", "echo start > /var/run/app/session.pid && sleep 3600"]
      securityContext:
        readOnlyRootFilesystem: true
      volumeMounts:
        - name: app-run
          mountPath: /var/run/app
  volumes:
    - name: app-run
      emptyDir: {}
EOF

kubectl wait --for=condition=Ready pod/session-tracker -n q109-50-crashloop-readonly-volume-mismatch --timeout=60s
```
