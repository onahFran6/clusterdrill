# q103-37: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/

```sh
kubectl label pods -n q103-37-combined-fieldselector-labelselector-bulk-label \
  --field-selector=status.phase=Running \
  -l tier=batch \
  synced=true
```
