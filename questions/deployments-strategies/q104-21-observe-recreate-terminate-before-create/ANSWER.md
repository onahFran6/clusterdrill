# q104-21-observe-recreate-terminate-before-create: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#recreate-deployment

```sh
kubectl set image deployment/batch-loader batch-loader=busybox:1.36.1 \
  -n q104-21-observe-recreate-terminate-before-create

kubectl rollout status deployment/batch-loader \
  -n q104-21-observe-recreate-terminate-before-create --timeout=60s

# rollout status can return a moment before the last old pod object is
# fully gone - wait until only new-image, ready pods remain before grading.
for i in $(seq 1 30); do
  old="$(kubectl get pods -n q104-21-observe-recreate-terminate-before-create \
    -l app=batch-loader -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' 2>/dev/null \
    | grep -v '^busybox:1.36.1$' | wc -l | tr -d ' ')"
  ready_count="$(kubectl get pods -n q104-21-observe-recreate-terminate-before-create \
    -l app=batch-loader -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null \
    | grep -c true)"
  [ "$old" = "0" ] && [ "$ready_count" = "3" ] && break
  sleep 1
done
```
