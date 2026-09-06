# q109-12: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#binding

A bound PVC's storage request can only be increased in place (resizing), and this
StorageClass doesn't allow expansion, so recreate the claim asking for a size the PV can
actually satisfy.

```sh
NS=q109-12-pv-capacity-access-mode-mismatch

kubectl delete pvc oversized-claim -n "$NS"

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oversized-claim
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual-q109-12
  resources:
    requests:
      storage: 200Mi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/oversized-claim -n "$NS" --timeout=60s
```
