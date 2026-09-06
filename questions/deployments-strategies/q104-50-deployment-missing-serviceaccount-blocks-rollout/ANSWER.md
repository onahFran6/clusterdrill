# q104-50-deployment-missing-serviceaccount-blocks-rollout: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

```sh
kubectl patch deployment payments-worker -n q104-50-deployment-missing-serviceaccount-blocks-rollout --type=json -p '
[
  {
    "op": "replace",
    "path": "/spec/template/spec/serviceAccountName",
    "value": "payments-runner"
  }
]
'

kubectl rollout status deployment/payments-worker -n q104-50-deployment-missing-serviceaccount-blocks-rollout --timeout=60s
```
