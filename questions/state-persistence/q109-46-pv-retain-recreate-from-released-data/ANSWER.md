# q109-46-pv-retain-recreate-from-released-data: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming

```sh
NS=q109-46-pv-retain-recreate-from-released-data

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: archive-pv-new
  labels:
    clusterdrill-question: $NS
spec:
  capacity:
    storage: 200Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /mnt/q109-46-archive
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: archive-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 200Mi
EOF
```
