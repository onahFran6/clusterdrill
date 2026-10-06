# q110-40-helm-chart-local-subchart-dependency: reference solution

Doc: https://helm.sh/docs/topics/charts/#chart-dependencies

```sh
cd $HOME/practice-work/q110-40-helm-chart-local-subchart-dependency/chart
helm dependency update
cd -

helm install demo $HOME/practice-work/q110-40-helm-chart-local-subchart-dependency/chart \
  -n q110-40-helm-chart-local-subchart-dependency --wait
```
