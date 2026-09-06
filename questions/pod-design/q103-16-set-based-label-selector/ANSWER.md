# q103-16: reference solution

Doc: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#set-based-requirement

```sh
kubectl get pods -n q103-16-set-based-label-selector -l 'region in (us,eu)'

kubectl label pods -n q103-16-set-based-label-selector -l 'region in (us,eu)' active=true
```
