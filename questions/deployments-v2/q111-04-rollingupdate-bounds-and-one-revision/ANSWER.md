# q111-04: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment

```sh
kubectl patch deployment relay -n q111-04-rollingupdate-bounds-and-one-revision \
  -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":2,"maxUnavailable":1}}}}'

kubectl rollout pause deployment/relay -n q111-04-rollingupdate-bounds-and-one-revision
kubectl set image deployment/relay nginx=nginx:1.27 -n q111-04-rollingupdate-bounds-and-one-revision
kubectl set env deployment/relay FEATURE_X=on -n q111-04-rollingupdate-bounds-and-one-revision
kubectl annotate deployment relay -n q111-04-rollingupdate-bounds-and-one-revision \
  kubernetes.io/change-cause="relay 1.27 + feature x"
kubectl rollout resume deployment/relay -n q111-04-rollingupdate-bounds-and-one-revision

kubectl rollout status deployment/relay -n q111-04-rollingupdate-bounds-and-one-revision --timeout=120s
```

At least 9 available with 10 replicas means at most 1 unavailable; never more than 12 total means
at most 2 surge. `rollout pause` stops the controller from reacting to the pod-template diff
after each individual `set` call, so both land in the template together and `resume` creates
exactly one new ReplicaSet (revision 2) instead of two. A strategy change alone is not a pod
template change, so patching `rollingUpdate` never creates a revision by itself.
