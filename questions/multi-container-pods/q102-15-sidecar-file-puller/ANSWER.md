# q102-15: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl apply -n q102-15-sidecar-file-puller -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: content-server
  labels:
    clusterdrill-question: q102-15-sidecar-file-puller
spec:
  containers:
    - name: content-puller
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo '<html>synced content</html>' > /www/index.html; sleep 30; done"]
      volumeMounts:
        - name: web-content
          mountPath: /www
    - name: web
      image: nginx:1.27-alpine
      volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
  volumes:
    - name: web-content
      emptyDir: {}
EOF
```
