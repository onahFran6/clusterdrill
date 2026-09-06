# q109-25-multi-container-subpath-partitioned-pvc: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath

```sh
kubectl apply -n q109-25-multi-container-subpath-partitioned-pvc -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: partitioned
spec:
  containers:
    - name: writer-a
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /data && echo a > /data/a.txt && sleep 3600"]
      volumeMounts:
        - name: shared-multi
          mountPath: /data
          subPath: section-a
    - name: writer-b
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /data && echo b > /data/b.txt && sleep 3600"]
      volumeMounts:
        - name: shared-multi
          mountPath: /data
          subPath: section-b
  volumes:
    - name: shared-multi
      persistentVolumeClaim:
        claimName: shared-multi
EOF

kubectl wait --for=condition=Ready pod/partitioned -n q109-25-multi-container-subpath-partitioned-pvc --timeout=60s
```
