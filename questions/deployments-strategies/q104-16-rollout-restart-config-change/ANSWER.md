# q104-16: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout_restart/

```sh
kubectl rollout restart deployment/worker-pool -n q104-16-rollout-restart-config-change

kubectl rollout status deployment/worker-pool -n q104-16-rollout-restart-config-change --timeout=60s

# rollout status can return a moment before the last old pod is fully gone -
# wait until only the new generation's pods remain before grading.
for i in $(seq 1 30); do
  old="$(kubectl get pods -n q104-16-rollout-restart-config-change -l app=worker-pool \
    --field-selector=status.phase!=Running -o name 2>/dev/null | wc -l | tr -d ' ')"
  ready_count="$(kubectl get pods -n q104-16-rollout-restart-config-change -l app=worker-pool \
    -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null | grep -c true)"
  [ "$old" = "0" ] && [ "$ready_count" = "3" ] && break
  sleep 1
done
```
