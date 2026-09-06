# q109-36-fix-hostpath-type-mismatch: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#hostpath

`hostPath.type` cannot be patched on a running Pod - delete and recreate it.

```sh
kubectl delete pod log-writer -n q109-36-fix-hostpath-type-mismatch --wait=true

kubectl apply -n q109-36-fix-hostpath-type-mismatch -f - <<EOF
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
        - name: logs
          mountPath: /var/log/app
  volumes:
    - name: logs
      hostPath:
        path: /mnt/q109-36-logs
        type: Directory
EOF

kubectl wait --for=condition=Ready pod/log-writer -n q109-36-fix-hostpath-type-mismatch --timeout=60s
```
