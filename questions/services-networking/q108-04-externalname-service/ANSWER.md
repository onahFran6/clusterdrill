# q108-04: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#externalname

```sh
kubectl apply -n q108-04-externalname-service -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: billing-db
spec:
  type: ExternalName
  externalName: db.internal.example.com
EOF
```
