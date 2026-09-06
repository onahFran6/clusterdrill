# q105-09: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-specific-path-in-the-volume

```sh
kubectl delete pod landing-page -n q105-09-configmap-volume-subpath

kubectl apply -n q105-09-configmap-volume-subpath -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: landing-page
  labels:
    app: landing-page
spec:
  containers:
    - name: landing-page
      image: nginx:1.25-alpine
      command: ["sh", "-c"]
      args:
        - "echo already-here > /usr/share/nginx/html/existing-notice.txt && exec nginx -g 'daemon off;'"
      volumeMounts:
        - name: site-config
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
  volumes:
    - name: site-config
      configMap:
        name: site-config
EOF

kubectl wait --for=condition=Ready pod/landing-page -n q105-09-configmap-volume-subpath --timeout=60s
```
