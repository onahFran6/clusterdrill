# q105-43-configmap-binarydata-from-file: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-object

```sh
kubectl create configmap app-assets \
  --from-file=$HOME/practice-work/q105-43-configmap-binarydata-from-file/assets/logo.bin \
  -n q105-43-configmap-binarydata-from-file

kubectl delete pod asset-server -n q105-43-configmap-binarydata-from-file

kubectl apply -n q105-43-configmap-binarydata-from-file -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: asset-server
  labels:
    app: asset-server
spec:
  containers:
    - name: asset-server
      image: nginx:1.25-alpine
      volumeMounts:
        - name: assets-vol
          mountPath: /etc/assets
  volumes:
    - name: assets-vol
      configMap:
        name: app-assets
EOF

kubectl wait --for=condition=Ready pod/asset-server -n q105-43-configmap-binarydata-from-file --timeout=60s
```
