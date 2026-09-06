# q108-34-service-type-loadbalancer-basic: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer

```sh
kubectl apply -n q108-34-service-type-loadbalancer-basic -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: webshop-svc
spec:
  type: LoadBalancer
  selector:
    app: webshop
  ports:
    - port: 80
      targetPort: 80
EOF
```
