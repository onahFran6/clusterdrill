# q104-06: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#max-surge

```sh
kubectl patch deployment image-resizer -n q104-06-tune-max-surge-fast-rollout --type=merge -p '
{
  "spec": {
    "strategy": {
      "type": "RollingUpdate",
      "rollingUpdate": {
        "maxSurge": "100%",
        "maxUnavailable": 0
      }
    }
  }
}
'

kubectl set image deployment/image-resizer image-resizer=nginx:1.25-alpine \
  -n q104-06-tune-max-surge-fast-rollout

kubectl rollout status deployment/image-resizer -n q104-06-tune-max-surge-fast-rollout --timeout=60s
```
