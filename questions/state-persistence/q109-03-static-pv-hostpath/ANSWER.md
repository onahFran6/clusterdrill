# q109-03: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes

```sh
NS=q109-03-static-pv-hostpath

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: q109-03-data-pv
  labels:
    clusterdrill-question: $NS
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/q109-03-data
EOF
```
