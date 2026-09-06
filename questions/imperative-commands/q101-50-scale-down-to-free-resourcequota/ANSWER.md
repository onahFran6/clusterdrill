# q101-50-scale-down-to-free-resourcequota: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/resource-quotas/

```sh
kubectl describe resourcequota task-quota -n q101-50-scale-down-to-free-resourcequota
kubectl get pods -n q101-50-scale-down-to-free-resourcequota

kubectl scale deployment/legacy-batch \
  -n q101-50-scale-down-to-free-resourcequota --replicas=1

# Wait for the terminated replica to actually go away AND for the
# ResourceQuota controller to reconcile its usage - both lag behind the
# instant `kubectl scale` returns.
for i in $(seq 1 30); do
  USED=$(kubectl get resourcequota task-quota -n q101-50-scale-down-to-free-resourcequota -o jsonpath='{.status.used.pods}')
  [ "$USED" -lt 2 ] && break
  sleep 2
done

kubectl run report-gen \
  -n q101-50-scale-down-to-free-resourcequota \
  --image=busybox:1.36 \
  --command -- sleep 3600
```
