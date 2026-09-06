# q104-38-tune-maxunavailable-percent-maxsurge-fixed: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#max-unavailable

```sh
kubectl patch deployment catalog-api -n q104-38-tune-maxunavailable-percent-maxsurge-fixed --type=merge -p '
{
  "spec": {
    "strategy": {
      "rollingUpdate": {
        "maxUnavailable": "20%",
        "maxSurge": 3
      }
    }
  }
}
'

kubectl rollout status deployment/catalog-api -n q104-38-tune-maxunavailable-percent-maxsurge-fixed --timeout=60s
```
