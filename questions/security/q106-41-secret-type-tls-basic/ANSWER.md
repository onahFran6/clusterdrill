# q106-41-secret-type-tls-basic: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets

```sh
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout /tmp/q106-41-tls.key -out /tmp/q106-41-tls.crt \
  -days 1 -subj "/CN=site.example.com"

kubectl create secret tls site-tls \
  --cert=/tmp/q106-41-tls.crt --key=/tmp/q106-41-tls.key \
  -n q106-41-secret-type-tls-basic
```
