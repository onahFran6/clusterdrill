# q103-22: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/

```sh
kubectl delete pods -n q103-22-field-selector-pod-phase-cleanup --field-selector=status.phase=Succeeded
```
