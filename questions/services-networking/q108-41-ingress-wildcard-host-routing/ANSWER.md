# q108-41-ingress-wildcard-host-routing: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#hostname-wildcards

```sh
kubectl apply -n q108-41-ingress-wildcard-host-routing -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tenant-portal-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: "*.tenants.example.com"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: tenant-portal-svc
                port:
                  number: 80
EOF
```
