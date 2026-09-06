# q109-39-pvc-selector-matchexpressions: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector

```sh
kubectl apply -n q109-39-pvc-selector-matchexpressions -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gold-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 50Mi
  selector:
    matchExpressions:
      - key: tier
        operator: In
        values:
          - gold
EOF
```
