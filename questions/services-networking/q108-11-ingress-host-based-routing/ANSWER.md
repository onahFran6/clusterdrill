# q108-11: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#name-based-virtual-hosting

```sh
kubectl apply -n q108-11-ingress-host-based-routing -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sites-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: blog.ckad.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: blog-svc
                port:
                  number: 80
    - host: api.ckad.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-svc
                port:
                  number: 8080
EOF
```
