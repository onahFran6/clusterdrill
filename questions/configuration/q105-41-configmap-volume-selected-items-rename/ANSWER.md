# q105-41-configmap-volume-selected-items-rename: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#add-configmap-data-to-a-specific-path-in-the-volume

```sh
kubectl delete pod site-renderer -n q105-41-configmap-volume-selected-items-rename

kubectl apply -n q105-41-configmap-volume-selected-items-rename -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: site-renderer
  labels:
    app: site-renderer
spec:
  containers:
    - name: site-renderer
      image: nginx:1.25-alpine
      volumeMounts:
        - name: site-config-vol
          mountPath: /etc/site
  volumes:
    - name: site-config-vol
      configMap:
        name: site-config
        items:
          - key: header.html
            path: head.html
          - key: footer.html
            path: foot.html
EOF

kubectl wait --for=condition=Ready pod/site-renderer -n q105-41-configmap-volume-selected-items-rename --timeout=60s
```
