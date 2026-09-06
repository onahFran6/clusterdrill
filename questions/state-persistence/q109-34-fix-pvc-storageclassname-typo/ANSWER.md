# q109-34-fix-pvc-storageclassname-typo: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#class-1

```sh
kubectl delete pvc reports-data -n q109-34-fix-pvc-storageclassname-typo --wait=true

kubectl apply -n q109-34-fix-pvc-storageclassname-typo -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: reports-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 100Mi
EOF
```
