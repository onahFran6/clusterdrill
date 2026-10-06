# q116-04-strip-the-prefix: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#rewrite-target

```sh
QUESTION_ID="q116-04-strip-the-prefix"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: legacy
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /\$2
spec:
  ingressClassName: nginx
  rules:
    - host: quasar.local
      http:
        paths:
          - path: /legacy(/|\$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: legacy-svc
                port:
                  number: 80
EOF
```
