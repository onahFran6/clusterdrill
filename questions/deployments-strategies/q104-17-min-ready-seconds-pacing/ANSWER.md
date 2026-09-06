# q104-17: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#min-ready-seconds

```sh
kubectl patch deployment event-bus -n q104-17-min-ready-seconds-pacing --type=merge \
  -p '{"spec": {"minReadySeconds": 10}}'

kubectl set image deployment/event-bus event-bus=nginx:1.25-alpine \
  -n q104-17-min-ready-seconds-pacing

kubectl rollout status deployment/event-bus -n q104-17-min-ready-seconds-pacing --timeout=90s
```
