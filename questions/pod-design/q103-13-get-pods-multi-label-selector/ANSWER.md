# q103-13: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/

```sh
kubectl get pods -n q103-13-get-pods-multi-label-selector -l tier=frontend,env=prod

kubectl label pod frontend-a -n q103-13-get-pods-multi-label-selector verified=true
```
