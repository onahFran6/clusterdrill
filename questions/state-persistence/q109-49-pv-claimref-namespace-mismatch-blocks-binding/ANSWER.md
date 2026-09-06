# q109-49-pv-claimref-namespace-mismatch-blocks-binding: reference solution

Doc: https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/persistent-volume-v1/#PersistentVolumeSpec

```sh
kubectl delete pv preassigned-pv --wait=true

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: preassigned-pv
  labels:
    clusterdrill-question: q109-49-pv-claimref-namespace-mismatch-blocks-binding
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /mnt/q109-49-preassigned
  claimRef:
    name: preassigned-claim
    namespace: q109-49-pv-claimref-namespace-mismatch-blocks-binding
EOF
```
