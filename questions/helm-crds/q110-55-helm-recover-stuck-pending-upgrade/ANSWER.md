# q110-55: reference solution

Doc: https://helm.sh/docs/helm/helm_rollback/

```sh
helm rollback stuck 1 -n q110-55-helm-recover-stuck-pending-upgrade --wait --timeout 60s

helm upgrade stuck questions/helm-crds/q110-55-helm-recover-stuck-pending-upgrade/chart \
  -n q110-55-helm-recover-stuck-pending-upgrade \
  --set image=nginx:1.27-alpine --wait --timeout 60s
```
