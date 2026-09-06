# q108-13: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#default-backend

```sh
kubectl apply -n q108-13-ingress-default-backend -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: docs-ingress
spec:
  ingressClassName: nginx
  defaultBackend:
    service:
      name: fallback-svc
      port:
        number: 80
  rules:
    - http:
        paths:
          - path: /docs
            pathType: Prefix
            backend:
              service:
                name: docs-svc
                port:
                  number: 80
EOF
```
