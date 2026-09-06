# q108-12: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#tls

```sh
kubectl apply -n q108-12-ingress-tls -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - secure.ckad.example.com
      secretName: secure-app-tls
  rules:
    - host: secure.ckad.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: secure-app-svc
                port:
                  number: 80
EOF
```
