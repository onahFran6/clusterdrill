# q104-32-recover-deployment-after-bad-rollback-wrong-revision: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment

```sh
QUESTION_ID="q104-32-recover-deployment-after-bad-rollback-wrong-revision"

# Inspect history to find which revision actually runs busybox:1.35.
kubectl rollout history deployment/billing-sync -n "$QUESTION_ID"

TARGET_REV="$(
  for r in $(kubectl rollout history deployment/billing-sync -n "$QUESTION_ID" \
      | awk 'NR>2 {print $1}'); do
    img="$(kubectl rollout history deployment/billing-sync -n "$QUESTION_ID" --revision="$r" \
      | grep -oE 'Image:\s+\S+' | awk '{print $2}')"
    if [ "$img" = "busybox:1.35" ]; then
      echo "$r"
      break
    fi
  done
)"

kubectl rollout undo deployment/billing-sync -n "$QUESTION_ID" --to-revision="$TARGET_REV"

kubectl rollout status deployment/billing-sync -n "$QUESTION_ID" --timeout=60s
```
