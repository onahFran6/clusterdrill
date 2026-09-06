# q110-03: reference solution

Doc: https://helm.sh/docs/helm/helm_upgrade/

```sh
helm upgrade site questions/helm-crds/q110-03-helm-upgrade-values/chart \
  -n q110-03-helm-upgrade-values --set image.tag=1.27-alpine --wait
```
