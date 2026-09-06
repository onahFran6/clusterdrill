# q108-07: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#session-stickiness

```sh
kubectl patch service session-store-svc -n q108-07-session-affinity-clientip --type merge -p '
{
  "spec": {
    "sessionAffinity": "ClientIP",
    "sessionAffinityConfig": {
      "clientIP": {
        "timeoutSeconds": 3600
      }
    }
  }
}'
```
