# q104-14: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment

```sh
STATUS=$(kubectl get deployment inventory -n q104-14-readiness-gate-stuck-rollout \
  -o jsonpath='{.status.conditions[?(@.type=="Progressing")].status}')

kubectl create configmap diagnosis \
  --from-literal=progressing-status="$STATUS" \
  -n q104-14-readiness-gate-stuck-rollout

kubectl label configmap diagnosis \
  clusterdrill-question=q104-14-readiness-gate-stuck-rollout \
  -n q104-14-readiness-gate-stuck-rollout
```
