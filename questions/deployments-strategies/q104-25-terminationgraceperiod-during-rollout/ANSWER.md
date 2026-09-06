# q104-25-terminationgraceperiod-during-rollout: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination

```sh
kubectl patch deployment worker-queue \
  -n q104-25-terminationgraceperiod-during-rollout \
  --type merge \
  -p '{"spec":{"template":{"spec":{"terminationGracePeriodSeconds":5}}}}'

kubectl rollout status deployment/worker-queue \
  -n q104-25-terminationgraceperiod-during-rollout --timeout=60s
```
