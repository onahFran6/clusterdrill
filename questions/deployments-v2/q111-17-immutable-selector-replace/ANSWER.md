# q111-17: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#selector

```sh
NS=q111-17-immutable-selector-replace

# Metadata-only change: no pod template touched, so no rollout.
kubectl annotate deployment wallet -n "$NS" owner=payments

# The selector is immutable on apps/v1 - a normal edit/apply is rejected
# ("field is immutable"). Delete and recreate from a modified copy of the
# live object is the only path; `replace --force` does both in one step.
kubectl get deployment wallet -n "$NS" -o json \
  | jq '.spec.selector.matchLabels.team = "fortuna" | .spec.template.metadata.labels.team = "fortuna"' \
  | kubectl replace --force -f -

kubectl rollout status deployment/wallet -n "$NS" --timeout=60s
```

Annotations live in `metadata`, outside the pod template, so adding one never triggers a
rollout. The selector is immutable precisely so a Deployment can never silently start adopting a
different set of pods; `kubectl replace --force` deletes the object and recreates it from the
given spec in one step, which is also why rollout history resets to revision 1 - it's a brand
new object, not a rolling update of the old one. Adding `team: fortuna` to the pod template alone
would have been allowed (a template's labels may be a superset of the selector) and would have
triggered a normal rolling update instead - but the selector itself can only ever go through
delete+recreate.
