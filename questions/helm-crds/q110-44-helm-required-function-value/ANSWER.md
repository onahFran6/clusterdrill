# q110-44-helm-required-function-value: reference solution

Doc: https://helm.sh/docs/chart_template_guide/functions_and_pipelines/

```sh
helm install demo questions/helm-crds/q110-44-helm-required-function-value/chart \
  -n q110-44-helm-required-function-value \
  --set apiKey=sk-live-92f3 \
  --wait
```
