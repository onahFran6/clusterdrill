# q109-13: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#hostpath

```sh
NS=q109-13-hostpath-volume-directory-or-create

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: log-writer
spec:
  containers:
    - name: log-writer
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: hostlogs
          mountPath: /var/log/app
  volumes:
    - name: hostlogs
      hostPath:
        path: /tmp/ckad-hostlogs
        type: DirectoryOrCreate
EOF
```
