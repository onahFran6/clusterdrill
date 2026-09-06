# q101-31-rollback-deployment-specific-revision: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment

```sh
NS=q101-31-rollback-deployment-specific-revision

# List every recorded revision.
kubectl rollout history deployment/orders-api -n "$NS"

# Inspect each revision's pod template to find the most recent one that
# actually ran a valid image (not just the one immediately before current,
# which is also broken).
TARGET_REV="$(
  for r in $(kubectl rollout history deployment/orders-api -n "$NS" \
      | awk 'NR>2 {print $1}' | sort -rn); do
    img="$(kubectl rollout history deployment/orders-api -n "$NS" --revision="$r" \
      | grep -oE 'Image:\s+\S+' | awk '{print $2}')"
    case "$img" in
      *missing*|*does-not-exist*) continue ;;
    esac
    echo "$r"
    break
  done
)"

kubectl rollout undo deployment/orders-api -n "$NS" --to-revision="$TARGET_REV"

kubectl rollout status deployment/orders-api -n "$NS" --timeout=60s
```
