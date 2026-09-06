# q105-02: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-configmaps-from-files

```sh
kubectl create configmap nginx-conf \
  --from-file=$HOME/practice-work/q105-02-configmap-from-file-volume/q105-02-nginx.conf \
  -n q105-02-configmap-from-file-volume

kubectl delete pod web-server -n q105-02-configmap-from-file-volume

kubectl apply -n q105-02-configmap-from-file-volume -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-server
  labels:
    app: web-server
spec:
  containers:
    - name: web-server
      image: nginx:1.25-alpine
      volumeMounts:
        - name: conf
          mountPath: /etc/nginx/conf.d
  volumes:
    - name: conf
      configMap:
        name: nginx-conf
EOF

kubectl wait --for=condition=Ready pod/web-server -n q105-02-configmap-from-file-volume --timeout=60s
```
