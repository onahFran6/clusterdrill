# q106-09: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/

```sh
ANSWER=$(kubectl auth can-i create deployments -n q106-09-auth-can-i-self)

kubectl create configmap can-i-result \
  --from-literal=answer="$ANSWER" \
  -n q106-09-auth-can-i-self
```
