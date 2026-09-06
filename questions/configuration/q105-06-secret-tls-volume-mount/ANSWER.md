# q105-06: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets

```sh
kubectl create secret tls edge-tls \
  --cert=$HOME/practice-work/q105-06-secret-tls-volume-mount/q105-06-tls.crt \
  --key=$HOME/practice-work/q105-06-secret-tls-volume-mount/q105-06-tls.key \
  -n q105-06-secret-tls-volume-mount

kubectl delete pod edge-proxy -n q105-06-secret-tls-volume-mount

kubectl apply -n q105-06-secret-tls-volume-mount -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: edge-proxy
  labels:
    app: edge-proxy
spec:
  containers:
    - name: edge-proxy
      image: nginx:1.25-alpine
      volumeMounts:
        - name: tls
          mountPath: /etc/nginx/tls
          readOnly: true
  volumes:
    - name: tls
      secret:
        secretName: edge-tls
EOF

kubectl wait --for=condition=Ready pod/edge-proxy -n q105-06-secret-tls-volume-mount --timeout=60s
```
