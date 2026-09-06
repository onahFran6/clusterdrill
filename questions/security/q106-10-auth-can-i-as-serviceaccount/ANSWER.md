# q106-10: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/

```sh
ANSWER=$(kubectl auth can-i delete deployments \
  --as=system:serviceaccount:q106-10-auth-can-i-as-serviceaccount:ci-deployer \
  -n q106-10-auth-can-i-as-serviceaccount)

kubectl create configmap delete-check \
  --from-literal=answer="$ANSWER" \
  -n q106-10-auth-can-i-as-serviceaccount
```
