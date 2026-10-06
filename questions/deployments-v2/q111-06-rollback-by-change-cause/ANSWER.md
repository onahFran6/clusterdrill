# q111-06: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-to-a-previous-revision

```sh
kubectl rollout history deployment/billing -n q111-06-rollback-by-change-cause
kubectl rollout history deployment/billing -n q111-06-rollback-by-change-cause --revision=2

kubectl rollout undo deployment/billing -n q111-06-rollback-by-change-cause --to-revision=2
kubectl rollout status deployment/billing -n q111-06-rollback-by-change-cause --timeout=60s

kubectl patch deployment billing -n q111-06-rollback-by-change-cause \
  -p '{"spec":{"revisionHistoryLimit":3}}'
```

`rollout history`'s `CHANGE-CAUSE` column shows revision 2 is `stable release`; its
`--revision=2` detail confirms it runs `httpd:2.4.58` with no `CACHE` env var. `rollout undo
--to-revision=2` restores that whole template - including the absence of `CACHE` - not a partial
patch, so the rollback becomes a brand-new revision (5) built from revision 2's exact content.
`revisionHistoryLimit` defaults to 10 and controls how many old, scaled-to-0 ReplicaSets are kept
for future rollbacks; setting it to 0 would remove the ability to roll back at all.
