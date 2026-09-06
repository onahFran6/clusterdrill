# q108-03: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#headless-services

```sh
kubectl apply -n q108-03-headless-service-dns -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: cache-node-headless
spec:
  clusterIP: None
  selector:
    app: cache-node
  ports:
    - port: 6379
      targetPort: 6379
EOF

kubectl wait --for=jsonpath='{.subsets[0].addresses[0].ip}' \
  endpoints/cache-node-headless -n q108-03-headless-service-dns --timeout=60s
```
