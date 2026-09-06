# q104-48-liveness-probe-crashloop-blocks-rollout: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

```sh
kubectl patch deployment session-api -n q104-48-liveness-probe-crashloop-blocks-rollout --type=json -p '
[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/livenessProbe/initialDelaySeconds",
    "value": 15
  }
]
'

kubectl rollout status deployment/session-api -n q104-48-liveness-probe-crashloop-blocks-rollout --timeout=120s
```
