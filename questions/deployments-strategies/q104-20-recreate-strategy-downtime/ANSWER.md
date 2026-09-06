# q104-20-recreate-strategy-downtime: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#recreate-deployment

```sh
kubectl patch deployment billing-worker -n q104-20-recreate-strategy-downtime \
  --type=json -p '[
    {"op": "remove", "path": "/spec/strategy/rollingUpdate"},
    {"op": "replace", "path": "/spec/strategy/type", "value": "Recreate"}
  ]'
```
