# q110-59: reference solution

Doc: https://helm.sh/docs/helm/helm_uninstall/

```sh
helm uninstall app -n q110-59-helm-uninstall-keep-history-reinstate --keep-history

helm history app -n q110-59-helm-uninstall-keep-history-reinstate

helm rollback app 1 -n q110-59-helm-uninstall-keep-history-reinstate --wait --timeout 60s
```
