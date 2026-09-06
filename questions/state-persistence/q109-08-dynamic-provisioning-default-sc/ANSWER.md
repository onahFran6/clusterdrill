# q109-08: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/storage-classes/#default-storageclass

```sh
NS=q109-08-dynamic-provisioning-default-sc

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-claim
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/dynamic-claim -n "$NS" --timeout=60s
```
