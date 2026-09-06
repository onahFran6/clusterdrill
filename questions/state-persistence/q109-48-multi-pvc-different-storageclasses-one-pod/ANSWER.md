# q109-48-multi-pvc-different-storageclasses-one-pod: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#persistentvolumeclaim

```sh
NS=q109-48-multi-pvc-different-storageclasses-one-pod

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cache-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-tier
  resources:
    requests:
      storage: 100Mi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: records-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: durable-tier
  resources:
    requests:
      storage: 200Mi
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: data-processor
spec:
  containers:
    - name: data-processor
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: cache
          mountPath: /cache
        - name: records
          mountPath: /records
  volumes:
    - name: cache
      persistentVolumeClaim:
        claimName: cache-claim
    - name: records
      persistentVolumeClaim:
        claimName: records-claim
EOF

kubectl wait --for=condition=Ready pod/data-processor -n "$NS" --timeout=60s
```
