# q109-18: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming

```sh
NS=q109-18-pv-reclaim-policy-delete

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: scratch-pv
  labels:
    clusterdrill-question: $NS
spec:
  capacity:
    storage: 50Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: ""
  hostPath:
    path: /tmp/ckad-scratch-pv
EOF
```
