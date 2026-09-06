# q104-05: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment

```sh
kubectl patch deployment api-gateway -n q104-05-tune-max-unavailable-zero --type=merge -p '
{
  "spec": {
    "strategy": {
      "type": "RollingUpdate",
      "rollingUpdate": {
        "maxUnavailable": 0,
        "maxSurge": 2
      }
    }
  }
}
'
```
