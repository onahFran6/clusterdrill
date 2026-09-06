# q104-18: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#proportional-scaling

```sh
kubectl scale deployment/media-transcoder --replicas=8 -n q104-18-scale-during-rollout

# The rollout stays stuck (broken readiness probe, untouched on purpose) -
# give the controller a moment to actually create the extra pods across
# both ReplicaSets before grading.
for i in $(seq 1 20); do
  total=$(kubectl get rs -n q104-18-scale-during-rollout -l app=media-transcoder \
    -o jsonpath='{.items[*].spec.replicas}' | tr ' ' '+')
  [ "$(( ${total:-0} ))" = "8" ] && break
  sleep 1
done
```
