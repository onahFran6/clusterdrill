# q109-41-readonlymany-two-pods-share-pvc: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

```sh
NS=q109-41-readonlymany-two-pods-share-pvc

for name in catalog-reader-a catalog-reader-b; do
  kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
spec:
  containers:
    - name: $name
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: catalog
          mountPath: /catalog
          readOnly: true
  volumes:
    - name: catalog
      persistentVolumeClaim:
        claimName: catalog-claim
        readOnly: true
EOF
done

kubectl wait --for=condition=Ready pod/catalog-reader-a pod/catalog-reader-b -n "$NS" --timeout=60s
```
