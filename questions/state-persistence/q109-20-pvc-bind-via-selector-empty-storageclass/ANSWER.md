# q109-20-pvc-bind-via-selector-empty-storageclass: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#binding

```sh
NS=q109-20-pvc-bind-via-selector-empty-storageclass

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: env-claim
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 100Mi
  selector:
    matchLabels:
      env: green
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/env-claim -n "$NS" --timeout=60s
```
