# q108-30-ingress-multiple-backends-wrong-service-port-name: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/ingress/#resource-backend

```sh
kubectl patch ingress payments-ingress -n q108-30-ingress-multiple-backends-wrong-service-port-name --type merge -p '{
  "spec": {
    "rules": [
      {
        "http": {
          "paths": [
            {
              "path": "/pay",
              "pathType": "Prefix",
              "backend": {
                "service": {
                  "name": "payments-svc",
                  "port": {
                    "name": "http-api"
                  }
                }
              }
            }
          ]
        }
      }
    ]
  }
}'
```
