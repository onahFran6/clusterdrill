# q110-40-helm-chart-local-subchart-dependency: reference solution

Doc: https://helm.sh/docs/topics/charts/#chart-dependencies

```sh
cd questions/helm-crds/q110-40-helm-chart-local-subchart-dependency/chart
helm dependency update
cd -

helm install demo questions/helm-crds/q110-40-helm-chart-local-subchart-dependency/chart \
  -n q110-40-helm-chart-local-subchart-dependency --wait
```
