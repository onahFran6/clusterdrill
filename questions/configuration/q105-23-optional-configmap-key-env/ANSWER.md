# q105-23-optional-configmap-key-env: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#define-container-environment-variables-using-configmap-data

```sh
kubectl delete pod flagreader -n q105-23-optional-configmap-key-env

kubectl apply -n q105-23-optional-configmap-key-env -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: flagreader
  labels:
    app: flagreader
spec:
  containers:
    - name: flagreader
      image: nginx:1.25-alpine
      env:
        - name: FEATURE_X
          valueFrom:
            configMapKeyRef:
              name: app-flags
              key: FEATURE_X
        - name: FEATURE_Y
          valueFrom:
            configMapKeyRef:
              name: app-flags
              key: FEATURE_Y
              optional: true
EOF

kubectl wait --for=condition=Ready pod/flagreader -n q105-23-optional-configmap-key-env --timeout=60s
```
