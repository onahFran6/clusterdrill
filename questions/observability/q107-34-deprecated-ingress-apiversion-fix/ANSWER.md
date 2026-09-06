# q107-34-deprecated-ingress-apiversion-fix: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules

`extensions/v1beta1` Ingress used `backend.serviceName`/`backend.servicePort` directly; the
current `networking.k8s.io/v1` API nests them under `backend.service.name`/`backend.service.port.number`
and requires an explicit `pathType`.

```sh
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: storefront-ingress
  namespace: q107-34-deprecated-ingress-apiversion-fix
spec:
  rules:
    - host: storefront.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: storefront-svc
                port:
                  number: 80
EOF
```
