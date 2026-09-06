# q110-32-helm-uninstall-name-reuse: reference solution

Doc: https://helm.sh/docs/helm/helm_uninstall/

```sh
NS=q110-32-helm-uninstall-name-reuse

helm uninstall demo -n "$NS"

helm install demo questions/helm-crds/q110-32-helm-uninstall-name-reuse/chart \
  -n "$NS" --wait
```
