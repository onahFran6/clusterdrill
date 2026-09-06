# q105-45-configmap-subpath-no-live-update: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/configmap/#mounted-configmaps-are-updated-automatically

```sh
kubectl patch configmap app-version -n q105-45-configmap-subpath-no-live-update \
  --type=merge \
  -p '{"data":{"version.txt":"v2.0.0"}}'

kubectl delete pod version-display -n q105-45-configmap-subpath-no-live-update

kubectl apply -n q105-45-configmap-subpath-no-live-update -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: version-display
  labels:
    app: version-display
spec:
  containers:
    - name: version-display
      image: nginx:1.25-alpine
      volumeMounts:
        - name: version-vol
          mountPath: /usr/share/nginx/html/version.txt
          subPath: version.txt
  volumes:
    - name: version-vol
      configMap:
        name: app-version
EOF

kubectl wait --for=condition=Ready pod/version-display -n q105-45-configmap-subpath-no-live-update --timeout=60s
```
