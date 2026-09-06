# q104-49-rollback-fails-no-history-fix-forward: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment

```sh
# kubectl rollout undo deployment/pricing-sync would fail here - there is
# only one revision (this broken one), so there's nothing earlier to target.
# Fix forward instead:
kubectl set image deployment/pricing-sync pricing-sync=alpine:3.19 \
  -n q104-49-rollback-fails-no-history-fix-forward

kubectl rollout status deployment/pricing-sync -n q104-49-rollback-fails-no-history-fix-forward --timeout=60s
```
