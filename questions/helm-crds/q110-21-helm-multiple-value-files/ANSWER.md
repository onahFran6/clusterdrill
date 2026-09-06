# q110-21-helm-multiple-value-files: reference solution

Doc: https://helm.sh/docs/helm/helm_install/

```sh
helm install stack questions/helm-crds/q110-21-helm-multiple-value-files/chart \
  -n q110-21-helm-multiple-value-files \
  -f questions/helm-crds/q110-21-helm-multiple-value-files/overrides/prod-values.yaml \
  --wait --timeout 60s
```
