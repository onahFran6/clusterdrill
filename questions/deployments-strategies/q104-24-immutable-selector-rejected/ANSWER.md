# q104-24-immutable-selector-rejected: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#selector

```sh
kubectl patch deployment notify-service -n q104-24-immutable-selector-rejected --type=merge -p '
{
  "spec": {
    "template": {
      "metadata": {
        "labels": {
          "app": "notify-service",
          "tier": "backend"
        }
      }
    }
  }
}
'

kubectl rollout status deployment/notify-service -n q104-24-immutable-selector-rejected --timeout=60s
```
