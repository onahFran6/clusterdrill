# q109-10: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes

A bound PVC's access modes can't be patched in place, so recreate the claim requesting
`ReadWriteOnce` instead of `ReadWriteMany`.

```sh
NS=q109-10-access-mode-rwo-vs-rwx

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
