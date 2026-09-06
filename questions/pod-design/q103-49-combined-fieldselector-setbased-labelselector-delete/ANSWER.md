# q103-49: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/

```sh
kubectl delete pods -n q103-49-combined-fieldselector-setbased-labelselector-delete \
  --field-selector=status.phase=Succeeded \
  -l 'env in (staging,prod)'
```
