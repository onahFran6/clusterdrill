# q109-37-pv-accessmodes-add-second-mode: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

`accessModes` cannot be patched on an existing PersistentVolume - delete and recreate it.

```sh
kubectl delete pv shared-docs-pv --wait=true

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: shared-docs-pv
  labels:
    clusterdrill-question: q109-37-pv-accessmodes-add-second-mode
spec:
  capacity:
    storage: 500Mi
  accessModes:
    - ReadWriteOnce
    - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /mnt/q109-37-docs
EOF
```
