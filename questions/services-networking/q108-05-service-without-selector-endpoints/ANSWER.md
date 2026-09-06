# q108-05: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors

```sh
kubectl apply -n q108-05-service-without-selector-endpoints -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: legacy-db
spec:
  ports:
    - port: 5432
EOF

kubectl apply -n q108-05-service-without-selector-endpoints -f - <<EOF
apiVersion: v1
kind: Endpoints
metadata:
  name: legacy-db
subsets:
  - addresses:
      - ip: 10.240.0.55
    ports:
      - port: 5432
EOF
```
