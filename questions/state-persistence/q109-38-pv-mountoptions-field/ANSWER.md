# q109-38-pv-mountoptions-field: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#mount-options

```sh
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: perf-data-pv
  labels:
    clusterdrill-question: q109-38-pv-mountoptions-field
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  mountOptions:
    - noatime
    - nobarrier
  hostPath:
    path: /mnt/q109-38-perf-data
EOF
```
