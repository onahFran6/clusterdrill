# q109-06: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#claims-as-volumes

```sh
NS=q109-06-pod-mounts-pvc

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: notes-app
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: notes
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: notes-storage
          mountPath: /data/notes
  volumes:
    - name: notes-storage
      persistentVolumeClaim:
        claimName: notes-pvc
EOF

kubectl wait --for=condition=Ready pod/notes-app -n "$NS" --timeout=60s
```
