# q109-10: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

`kubectl describe pvc/shared-claim` shows no matching volumes: the claim requests
`ReadWriteMany` but `q109-10-shared-pv` (`hostPath`-backed) only offers `ReadWriteOnce`.
A PVC's `accessModes` is immutable, and this claim was never bound, so recreate it requesting
`ReadWriteOnce` instead.

```sh
NS=q109-10-pvc-pending-shared-directory

kubectl delete pvc shared-claim -n "$NS"

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-claim
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual-q109-10
  resources:
    requests:
      storage: 1Gi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/shared-claim -n "$NS" --timeout=60s
```
