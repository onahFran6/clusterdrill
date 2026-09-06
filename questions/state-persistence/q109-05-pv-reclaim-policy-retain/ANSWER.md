# q109-05: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming

```sh
kubectl patch pv q109-05-audit-pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```
