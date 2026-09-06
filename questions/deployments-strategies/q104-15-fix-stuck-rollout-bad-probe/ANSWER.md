# q104-15: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#configure-probes

```sh
kubectl patch deployment checkout-api -n q104-15-fix-stuck-rollout-bad-probe --type=json -p '
[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/path",
    "value": "/"
  }
]
'

kubectl rollout status deployment/checkout-api -n q104-15-fix-stuck-rollout-bad-probe --timeout=60s
```
