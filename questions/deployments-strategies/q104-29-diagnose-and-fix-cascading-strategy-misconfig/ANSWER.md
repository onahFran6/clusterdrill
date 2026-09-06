# q104-29-diagnose-and-fix-cascading-strategy-misconfig: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#max-unavailable

```sh
kubectl patch deployment payments-web \
  -n q104-29-diagnose-and-fix-cascading-strategy-misconfig \
  --type strategic \
  -p '{
    "spec": {
      "strategy": {"rollingUpdate": {"maxUnavailable": 0, "maxSurge": 1}},
      "template": {
        "spec": {
          "containers": [
            {"name": "payments-web", "readinessProbe": {"httpGet": {"path": "/", "port": 80}, "periodSeconds": 2, "failureThreshold": 2}}
          ]
        }
      }
    }
  }'

kubectl rollout status deployment/payments-web \
  -n q104-29-diagnose-and-fix-cascading-strategy-misconfig --timeout=60s
```
