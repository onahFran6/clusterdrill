# q109-16: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath

```sh
NS=q109-16-volume-subpath-single-file

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: config-reader
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: config-reader
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: storage
          mountPath: /etc/app.conf
          subPath: app.conf
  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: shared-storage
EOF

kubectl wait --for=condition=Ready pod/config-reader -n "$NS" --timeout=60s
```
