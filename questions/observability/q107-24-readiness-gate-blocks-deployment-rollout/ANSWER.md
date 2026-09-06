# q107-24-readiness-gate-blocks-deployment-rollout: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#checking-rollout-status

```sh
# 1. Diagnose: rollout status hangs, UP-TO-DATE < 3, new pod is stuck.
kubectl rollout status deployment/checkout-api -n q107-24-readiness-gate-blocks-deployment-rollout --timeout=5s || true
kubectl get deployment checkout-api -n q107-24-readiness-gate-blocks-deployment-rollout
kubectl get rs -n q107-24-readiness-gate-blocks-deployment-rollout -l app=checkout-api

NEW_POD=$(kubectl get pods -n q107-24-readiness-gate-blocks-deployment-rollout \
  -l app=checkout-api \
  --field-selector=status.phase!=Running \
  -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "$NEW_POD" -n q107-24-readiness-gate-blocks-deployment-rollout | tail -n 20

kubectl rollout history deployment/checkout-api -n q107-24-readiness-gate-blocks-deployment-rollout

# 2. Fix forward: correct the typo'd tag back to nginx:1.25-alpine. Do NOT
#    `kubectl rollout undo` - that would just revert to the pre-update tag
#    instead of proving the candidate fixed the actual bad image.
kubectl set image deployment/checkout-api nginx=nginx:1.25-alpine -n q107-24-readiness-gate-blocks-deployment-rollout

# 3. Wait for the corrected rollout to finish.
kubectl rollout status deployment/checkout-api -n q107-24-readiness-gate-blocks-deployment-rollout --timeout=120s
```
