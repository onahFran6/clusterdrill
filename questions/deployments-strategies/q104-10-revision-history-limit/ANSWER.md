# q104-10: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#clean-up-policy

```sh
kubectl patch deployment audit-log -n q104-10-revision-history-limit --type=merge \
  -p '{"spec": {"revisionHistoryLimit": 2}}'

kubectl set image deployment/audit-log audit-log=nginx:1.26-alpine \
  -n q104-10-revision-history-limit

kubectl rollout status deployment/audit-log -n q104-10-revision-history-limit --timeout=60s

# The controller prunes old ReplicaSets asynchronously after the rollout
# completes - give it a moment to catch up before grading.
for i in $(seq 1 20); do
  old_count=$(kubectl get rs -n q104-10-revision-history-limit -l app=audit-log \
    -o jsonpath='{range .items[?(@.spec.replicas==0)]}{.metadata.name}{"\n"}{end}' | sed '/^$/d' | wc -l | tr -d ' ')
  [ "$old_count" -le 2 ] && break
  sleep 1
done
```
