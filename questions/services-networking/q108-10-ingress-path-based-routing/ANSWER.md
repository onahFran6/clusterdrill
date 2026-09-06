# q108-10: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#simple-fanout

```sh
kubectl apply -n q108-10-ingress-path-based-routing -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop-ingress
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /catalog
            pathType: Prefix
            backend:
              service:
                name: catalog-svc
                port:
                  number: 80
          - path: /checkout
            pathType: Prefix
            backend:
              service:
                name: checkout-svc
                port:
                  number: 80
EOF
```
