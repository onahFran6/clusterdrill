# q101-36-create-secret-tls-imperative: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets

```sh
kubectl create secret tls web-tls \
  -n q101-36-create-secret-tls-imperative \
  --cert="$HOME/practice-work/q101-36-create-secret-tls-imperative/tls.crt" \
  --key="$HOME/practice-work/q101-36-create-secret-tls-imperative/tls.key"
```
