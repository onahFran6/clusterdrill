# q110-37-helm-set-flag-precedence-order: reference solution

Doc: https://helm.sh/docs/chart_template_guide/values_files/#overriding-values-from-the-command-line

```sh
helm install demo questions/helm-crds/q110-37-helm-set-flag-precedence-order/chart \
  -n q110-37-helm-set-flag-precedence-order \
  --set logLevel=debug \
  --set logLevel=warn \
  --wait
```
