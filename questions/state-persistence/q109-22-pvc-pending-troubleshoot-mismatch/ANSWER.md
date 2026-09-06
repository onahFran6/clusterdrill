# q109-22-pvc-pending-troubleshoot-mismatch: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#binding

A PersistentVolume's capacity is immutable once created, so the only fix is to delete
the too-small PV and recreate it with enough capacity for the pending claim to bind to.

```sh
NS=q109-22-pvc-pending-troubleshoot-mismatch

kubectl delete pv fix-me-pv --wait=true

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: fix-me-pv
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
    path: /tmp/ckad-fix-me-pv
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/fix-me-claim -n "$NS" --timeout=60s
```
