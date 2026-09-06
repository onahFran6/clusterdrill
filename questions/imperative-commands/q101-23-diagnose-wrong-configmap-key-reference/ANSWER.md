# q101-23-diagnose-wrong-configmap-key-reference: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#define-container-environment-variables-using-configmap-data

```sh
kubectl describe pod/settings-reader -n q101-23-diagnose-wrong-configmap-key-reference
kubectl get events -n q101-23-diagnose-wrong-configmap-key-reference --sort-by='.lastTimestamp'

kubectl delete pod settings-reader -n q101-23-diagnose-wrong-configmap-key-reference

kubectl apply -n q101-23-diagnose-wrong-configmap-key-reference -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: settings-reader
  labels:
    app: settings-reader
spec:
  containers:
    - name: settings-reader
      image: nginx:1.25-alpine
      envFrom:
        - configMapRef:
            name: app-settings
      env:
        - name: MAX_CONN
          valueFrom:
            configMapKeyRef:
              name: app-settings
              key: MAX_CONNECTIONS
EOF

kubectl wait --for=condition=Ready pod/settings-reader -n q101-23-diagnose-wrong-configmap-key-reference --timeout=60s
```
