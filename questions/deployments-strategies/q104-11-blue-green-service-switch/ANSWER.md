# q104-11: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service

```sh
kubectl patch service web-svc -n q104-11-blue-green-service-switch --type=merge -p '
{
  "spec": {
    "selector": {
      "app": "web",
      "version": "green"
    }
  }
}
'
```
