# q103-42: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#equality-based-requirement

```sh
kubectl label pods -n q103-42-label-selector-inequality-notequals-exclude \
  -l env!=prod \
  maintenance-window=true
```
