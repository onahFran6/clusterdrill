# q109-30: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/#allow-volume-expansion

```sh
NS=q109-30-pvc-immutable-recreate-not-patch

kubectl delete pvc resize-test -n "$NS"

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: resize-test
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 250Mi
EOF
```
