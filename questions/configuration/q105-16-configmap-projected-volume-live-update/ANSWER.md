# q105-16: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/projected-volumes/

```sh
kubectl patch configmap banner-config -n q105-16-configmap-projected-volume-live-update \
  --type=merge -p '{"data":{"banner.txt":"v2-updated"}}'
```
