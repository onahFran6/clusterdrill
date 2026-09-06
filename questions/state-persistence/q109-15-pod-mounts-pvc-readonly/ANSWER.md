# q109-15-pod-mounts-pvc-readonly: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#claims-as-volumes

```sh
NS=q109-15-pod-mounts-pvc-readonly

kubectl delete pod reader-app -n "$NS" --ignore-not-found --wait=true

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: reader-app
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
          readOnly: true
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: readonly-claim
EOF

kubectl wait --for=condition=Ready pod/reader-app -n "$NS" --timeout=60s
```
