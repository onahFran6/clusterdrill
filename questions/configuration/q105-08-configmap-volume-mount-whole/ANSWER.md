# q105-08: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#populate-a-volume-with-data-stored-in-a-configmap

```sh
kubectl delete pod report-service -n q105-08-configmap-volume-mount-whole

kubectl apply -n q105-08-configmap-volume-mount-whole -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: report-service
  labels:
    app: report-service
spec:
  containers:
    - name: report-service
      image: nginx:1.25-alpine
      volumeMounts:
        - name: config
          mountPath: /etc/app-config
  volumes:
    - name: config
      configMap:
        name: app-config
EOF

kubectl wait --for=condition=Ready pod/report-service -n q105-08-configmap-volume-mount-whole --timeout=60s
```
