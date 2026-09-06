# q109-04: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#binding

```sh
NS=q109-04-pvc-bind-static-pv

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-claim
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual-q109-04
  resources:
    requests:
      storage: 1Gi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/data-claim -n "$NS" --timeout=60s
```
