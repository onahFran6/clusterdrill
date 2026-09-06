# q110-29: reference solution

Doc: https://helm.sh/docs/helm/helm_rollback/

```sh
helm history app -n q110-29-helm-rollback-values-drift
helm rollback app 1 -n q110-29-helm-rollback-values-drift --wait
```
